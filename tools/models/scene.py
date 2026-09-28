"""Blender helpers: meshes from numpy arrays, materials, a product-photo studio and renders.

Runs with Blender as a Python module (`pip install bpy`), headless, rendering with Cycles on CPU.
"""

from __future__ import annotations

import math

import bpy
import numpy as np
from mathutils import Vector

# ---------------------------------------------------------------------------------------------
# Colors
# ---------------------------------------------------------------------------------------------


def srgb(hex_color):
    """'#rrggbb' -> linear RGB floats."""
    h = hex_color.lstrip("#")
    c = np.array([int(h[i : i + 2], 16) / 255.0 for i in (0, 2, 4)])
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def mix(a, b, t):
    t = np.asarray(t, dtype=np.float64)[..., None]
    return a * (1 - t) + b * t


# ---------------------------------------------------------------------------------------------
# Scene objects
# ---------------------------------------------------------------------------------------------


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def mesh_object(name, verts, faces, vertex_normals=None, colors=None, attributes=None, material=None, parent=None):
    """A mesh object from numpy arrays, smooth shaded.

    `colors` (N, 3) linear RGB per vertex become the "Col" attribute; `attributes` maps extra
    per-vertex float attribute names to (N,) arrays (roughness, subsurface ...).
    """
    me = bpy.data.meshes.new(name)
    verts = np.asarray(verts, dtype=np.float32)
    faces = np.asarray(faces, dtype=np.int32)
    if vertex_normals is not None:
        # wind faces to agree with the given outward normals
        a, b, c = verts[faces[:, 0]], verts[faces[:, 1]], verts[faces[:, 2]]
        fn = np.cross(b - a, c - a)
        agree = np.einsum("ij,ij->i", fn, vertex_normals[faces[:, 0]])
        if np.mean(agree > 0) < 0.5:
            faces = faces[:, ::-1].copy()
    me.vertices.add(len(verts))
    me.vertices.foreach_set("co", verts.ravel())
    me.loops.add(faces.size)
    me.loops.foreach_set("vertex_index", faces.ravel())
    me.polygons.add(len(faces))
    me.polygons.foreach_set("loop_start", np.arange(0, faces.size, 3, dtype=np.int32))
    me.update()
    me.polygons.foreach_set("use_smooth", np.ones(len(faces), dtype=bool))
    if vertex_normals is not None:
        me.normals_split_custom_set_from_vertices(np.asarray(vertex_normals, dtype=np.float32))
    if colors is not None:
        attr = me.color_attributes.new("Col", "FLOAT_COLOR", "POINT")
        rgba = np.ones((len(verts), 4), dtype=np.float32)
        rgba[:, :3] = colors
        attr.data.foreach_set("color", rgba.ravel())
    for key, values in (attributes or {}).items():
        attr = me.attributes.new(key, "FLOAT", "POINT")
        attr.data.foreach_set("value", np.asarray(values, dtype=np.float32))
    me.update()
    obj = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(obj)
    if material is not None:
        me.materials.append(material)
    if parent is not None:
        obj.parent = parent
    return obj


def decimate(obj, ratio, sharp_angle=None):
    """Collapse-decimate `obj` in place (keeps paint attributes), returning its triangle count.

    With `sharp_angle` (degrees), edges folding more than that are shaded hard, like a game asset
    with smoothing groups: crisp bevels on fins, soles and teeth, smooth rounded forms elsewhere.
    """
    me = obj.data
    if me.has_custom_normals:
        bpy.context.view_layer.objects.active = obj
        with bpy.context.temp_override(object=obj, active_object=obj):
            bpy.ops.mesh.customdata_custom_splitnormals_clear()
    mod = obj.modifiers.new("Decimate", "DECIMATE")
    mod.decimate_type = "COLLAPSE"
    mod.ratio = min(1.0, ratio)
    mod.use_collapse_triangulate = True
    depsgraph = bpy.context.evaluated_depsgraph_get()
    evaluated = obj.evaluated_get(depsgraph)
    new = bpy.data.meshes.new_from_object(evaluated)
    obj.modifiers.clear()
    obj.data = new
    new.polygons.foreach_set("use_smooth", np.ones(len(new.polygons), dtype=bool))
    if sharp_angle is not None:
        new.set_sharp_from_angle(angle=math.radians(sharp_angle))
    return len(new.polygons)


def empty(name, parent=None):
    obj = bpy.data.objects.new(name, None)
    bpy.context.scene.collection.objects.link(obj)
    if parent is not None:
        obj.parent = parent
    return obj


# ---------------------------------------------------------------------------------------------
# Materials
# ---------------------------------------------------------------------------------------------


def material(name, color=None, roughness=0.5, coat=0.0, coat_roughness=0.08, subsurface=0.0, sheen=0.0,
             specular=0.5, vertex_color=False, attributes=()):
    """A Principled BSDF material.

    With `vertex_color` the base color comes from the "Col" attribute. `attributes` lists
    per-vertex float attributes wired to sockets: ("Roughness", "Subsurface Weight", ...).
    """
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    bsdf = nodes["Principled BSDF"]
    if color is not None:
        bsdf.inputs["Base Color"].default_value = (*srgb(color), 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Specular IOR Level"].default_value = specular
    bsdf.inputs["Coat Weight"].default_value = coat
    bsdf.inputs["Coat Roughness"].default_value = coat_roughness
    bsdf.inputs["Sheen Weight"].default_value = sheen
    bsdf.inputs["Sheen Roughness"].default_value = 0.4
    if subsurface > 0:
        bsdf.inputs["Subsurface Weight"].default_value = subsurface
        bsdf.inputs["Subsurface Radius"].default_value = (1.0, 0.35, 0.2)
        bsdf.inputs["Subsurface Scale"].default_value = 0.06
    if vertex_color:
        node = nodes.new("ShaderNodeVertexColor")
        node.layer_name = "Col"
        links.new(node.outputs["Color"], bsdf.inputs["Base Color"])
    for socket in attributes:
        node = nodes.new("ShaderNodeAttribute")
        node.attribute_name = socket.replace(" ", "")
        links.new(node.outputs["Fac"], bsdf.inputs[socket])
    return mat


def _stud_group(size=0.34, radius=0.12, bevel=0.07):
    """Node group: height (0 in the grooves, 1 on top) of a grid of rounded-square studs.

    Input is a 2D coordinate in stud cells (x, y; z ignored). Each cell holds one raised rounded
    square of half-size `size` with corner `radius` and a soft `bevel`, all in cell units.
    """
    name = f"StudHeight_{size}_{radius}_{bevel}"
    group = bpy.data.node_groups.get(name)
    if group:
        return group
    group = bpy.data.node_groups.new(name, "ShaderNodeTree")
    group.interface.new_socket("Coord", in_out="INPUT", socket_type="NodeSocketVector")
    group.interface.new_socket("Height", in_out="OUTPUT", socket_type="NodeSocketFloat")
    nodes, links = group.nodes, group.links
    gin = nodes.new("NodeGroupInput")
    gout = nodes.new("NodeGroupOutput")

    def vmath(op, a, b=None):
        node = nodes.new("ShaderNodeVectorMath")
        node.operation = op
        links.new(a, node.inputs[0])
        if b is not None:
            if isinstance(b, tuple):
                node.inputs[1].default_value = b
            else:
                links.new(b, node.inputs[1])
        return node.outputs[1] if op in ("LENGTH", "DOT_PRODUCT", "DISTANCE") else node.outputs[0]

    def math(op, a, b):
        node = nodes.new("ShaderNodeMath")
        node.operation = op
        for i, v in enumerate((a, b)):
            if isinstance(v, float):
                node.inputs[i].default_value = v
            else:
                links.new(v, node.inputs[i])
        return node.outputs[0]

    flat = vmath("MULTIPLY", gin.outputs["Coord"], (1.0, 1.0, 0.0))
    cell = vmath("SUBTRACT", vmath("FRACTION", flat), (0.5, 0.5, 0.0))
    a = vmath("SUBTRACT", vmath("ABSOLUTE", cell), (size - radius, size - radius, 0.0))
    outside = vmath("LENGTH", vmath("MAXIMUM", a, (0.0, 0.0, 0.0)))
    sep = nodes.new("ShaderNodeSeparateXYZ")
    links.new(a, sep.inputs[0])
    inside = math("MINIMUM", math("MAXIMUM", sep.outputs["X"], sep.outputs["Y"]), 0.0)
    dist = math("SUBTRACT", math("ADD", outside, inside), radius)
    ramp = nodes.new("ShaderNodeMapRange")
    ramp.interpolation_type = "SMOOTHSTEP"
    ramp.inputs["From Min"].default_value = bevel * 0.5
    ramp.inputs["From Max"].default_value = -bevel * 0.5
    links.new(dist, ramp.inputs["Value"])
    links.new(ramp.outputs["Result"], gout.inputs["Height"])
    return group


def add_studs(mat, pitch=0.11, strength=0.9, distance=0.016, groove=0.16, attribute="Studs"):
    """Cover a Principled material with a dense grid of small raised rounded-square studs.

    The grid is projected along each point's dominant axis (object space), so studs sit square on
    the flat panels of blocky shapes and stay aligned from part to part, like a Roblox surface. It
    fades out on bevels (where no axis dominates) and wherever the per-vertex `attribute` is 0.
    Grooves are darkened a little so the pattern reads in flat lighting too.
    """
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    bsdf = nodes["Principled BSDF"]
    coords = nodes.new("ShaderNodeTexCoord")
    scaled = nodes.new("ShaderNodeVectorMath")
    scaled.operation = "SCALE"
    scaled.inputs["Scale"].default_value = 1.0 / pitch
    links.new(coords.outputs["Object"], scaled.inputs[0])
    sp = nodes.new("ShaderNodeSeparateXYZ")
    links.new(scaled.outputs[0], sp.inputs[0])
    group = _stud_group()

    def height(u, v):
        comb = nodes.new("ShaderNodeCombineXYZ")
        links.new(u, comb.inputs["X"])
        links.new(v, comb.inputs["Y"])
        node = nodes.new("ShaderNodeGroup")
        node.node_tree = group
        links.new(comb.outputs[0], node.inputs["Coord"])
        return node.outputs["Height"]

    def math(op, a, b, clamp=False):
        node = nodes.new("ShaderNodeMath")
        node.operation = op
        node.use_clamp = clamp
        for i, v in enumerate((a, b)):
            if isinstance(v, float):
                node.inputs[i].default_value = v
            else:
                links.new(v, node.inputs[i])
        return node.outputs[0]

    hx = height(sp.outputs["Y"], sp.outputs["Z"])
    hy = height(sp.outputs["X"], sp.outputs["Z"])
    hz = height(sp.outputs["X"], sp.outputs["Y"])
    nabs = nodes.new("ShaderNodeVectorMath")
    nabs.operation = "ABSOLUTE"
    links.new(coords.outputs["Normal"], nabs.inputs[0])
    sn = nodes.new("ShaderNodeSeparateXYZ")
    links.new(nabs.outputs[0], sn.inputs[0])
    ax, ay, az = sn.outputs["X"], sn.outputs["Y"], sn.outputs["Z"]
    wx = math("MULTIPLY", math("GREATER_THAN", ax, ay), math("GREATER_THAN", ax, az))
    wy = math("MULTIPLY", math("SUBTRACT", 1.0, math("GREATER_THAN", ax, ay)), math("GREATER_THAN", ay, az))
    wz = math("SUBTRACT", math("SUBTRACT", 1.0, wx), wy, clamp=True)
    h = math("ADD", math("ADD", math("MULTIPLY", hx, wx), math("MULTIPLY", hy, wy)), math("MULTIPLY", hz, wz))
    # only on faces that clearly face one axis, and only where the paint asks for studs
    dominant = math("MAXIMUM", math("MAXIMUM", ax, ay), az)
    fade = nodes.new("ShaderNodeMapRange")
    fade.inputs["From Min"].default_value = 0.74
    fade.inputs["From Max"].default_value = 0.82
    links.new(dominant, fade.inputs["Value"])
    if attribute:
        attr = nodes.new("ShaderNodeAttribute")
        attr.attribute_name = attribute
        mask = math("MULTIPLY", fade.outputs["Result"], attr.outputs["Fac"])
    else:
        mask = fade.outputs["Result"]
    bump = nodes.new("ShaderNodeBump")
    bump.inputs["Distance"].default_value = distance
    links.new(math("MULTIPLY", mask, strength), bump.inputs["Strength"])
    links.new(h, bump.inputs["Height"])
    links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
    # darken grooves: colour * (1 - groove * mask * (1 - h))
    shade = math("SUBTRACT", 1.0, math("MULTIPLY", math("MULTIPLY", mask, groove), math("SUBTRACT", 1.0, h)))
    base_link = bsdf.inputs["Base Color"].links[0] if bsdf.inputs["Base Color"].links else None
    mul = nodes.new("ShaderNodeMix")
    mul.data_type = "RGBA"
    mul.blend_type = "MULTIPLY"
    mul.inputs["Factor"].default_value = 1.0
    if base_link:
        links.new(base_link.from_socket, mul.inputs[6])
    else:
        mul.inputs[6].default_value = bsdf.inputs["Base Color"].default_value
    comb = nodes.new("ShaderNodeCombineXYZ")
    for key in ("X", "Y", "Z"):
        links.new(shade, comb.inputs[key])
    links.new(comb.outputs[0], mul.inputs[7])
    links.new(mul.outputs[2], bsdf.inputs["Base Color"])
    return mat


def eye_material(name, iris="#3a2a1c", iris_edge="#140c07", pupil_size=0.42, iris_size=0.72, highlight=False):
    """A glossy eyeball whose pupil (and optional iris) faces the object's local +Z axis.

    `iris=None` gives a toy eye: white with a black pupil. `highlight` paints a catchlight dot
    up and to the left of the pupil (local -X, +Y), so it reads even in flat lighting.
    """
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    bsdf = nodes["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = 0.15
    bsdf.inputs["Coat Weight"].default_value = 0.6
    bsdf.inputs["Coat Roughness"].default_value = 0.05
    coords = nodes.new("ShaderNodeTexCoord")
    norm = nodes.new("ShaderNodeVectorMath")
    norm.operation = "NORMALIZE"
    links.new(coords.outputs["Object"], norm.inputs[0])
    sep = nodes.new("ShaderNodeSeparateXYZ")
    links.new(norm.outputs["Vector"], sep.inputs[0])
    # cos(angle from the gaze axis) -> sclera / iris / pupil
    ramp = nodes.new("ShaderNodeValToRGB")
    cr = ramp.color_ramp
    cr.interpolation = "LINEAR"
    cos_pupil = math.cos(math.asin(pupil_size * 0.62))
    if iris is None:
        stops = [(0.0, "#fbfaf6"), (cos_pupil - 0.004, "#fbfaf6"), (cos_pupil + 0.004, "#0b0b10"), (1.0, "#0b0b10")]
    else:
        cos_iris = math.cos(math.asin(iris_size * 0.62))
        stops = [
            (0.0, "#f4f1ea"),
            (cos_iris - 0.02, "#ebe6dc"),
            (cos_iris - 0.004, "#1c120c"),
            (cos_iris + 0.004, iris_edge),
            (cos_iris + (cos_pupil - cos_iris) * 0.55, iris),
            (cos_pupil - 0.004, iris),
            (cos_pupil + 0.002, "#050404"),
            (1.0, "#050404"),
        ]
    cr.elements[0].position = stops[0][0]
    cr.elements[0].color = (*srgb(stops[0][1]), 1)
    cr.elements[1].position = stops[-1][0]
    cr.elements[1].color = (*srgb(stops[-1][1]), 1)
    for pos, col in stops[1:-1]:
        el = cr.elements.new(max(0.0, min(1.0, pos)))
        el.color = (*srgb(col), 1)
    links.new(sep.outputs["Z"], ramp.inputs["Fac"])
    color_out = ramp.outputs["Color"]
    if highlight:
        spot = nodes.new("ShaderNodeVectorMath")
        spot.operation = "DISTANCE"
        spot.inputs[1].default_value = tuple(np.array([-0.3, 0.32, 0.9]) / np.linalg.norm([-0.3, 0.32, 0.9]))
        links.new(norm.outputs["Vector"], spot.inputs[0])
        mask = nodes.new("ShaderNodeMapRange")
        mask.inputs["From Min"].default_value = 0.2
        mask.inputs["From Max"].default_value = 0.17
        links.new(spot.outputs["Value"], mask.inputs["Value"])
        mix_node = nodes.new("ShaderNodeMix")
        mix_node.data_type = "RGBA"
        links.new(mask.outputs["Result"], mix_node.inputs["Factor"])
        links.new(color_out, mix_node.inputs[6])
        mix_node.inputs[7].default_value = (1, 1, 1, 1)
        color_out = mix_node.outputs[2]
        bsdf.inputs["Emission Color"].default_value = (1, 1, 1, 1)
        links.new(mask.outputs["Result"], bsdf.inputs["Emission Strength"])
    links.new(color_out, bsdf.inputs["Base Color"])
    return mat


# ---------------------------------------------------------------------------------------------
# Studio
# ---------------------------------------------------------------------------------------------


def cyclorama(color="#e8dfd3", radius=7.0, depth=14.0, width=80.0, height=40.0, name="Cyclorama"):
    """A seamless photo-studio backdrop: floor curving up into a back wall at +y."""
    profile = []
    for i in range(24):
        profile.append((-60.0 + i * (60.0 + depth - radius) / 23.0, 0.0))
    for i in range(1, 33):
        a = (i / 32.0) * (math.pi / 2)
        profile.append((depth - radius + math.sin(a) * radius, radius - math.cos(a) * radius))
    for i in range(1, 6):
        profile.append((depth, radius + i * (height - radius) / 5.0))
    xs = np.linspace(-width / 2, width / 2, 9)
    verts = [(x, y, z) for x in xs for (y, z) in profile]
    n = len(profile)
    faces = []
    for i in range(len(xs) - 1):
        for j in range(n - 1):
            a = i * n + j
            b = (i + 1) * n + j
            faces.append((a, a + 1, b + 1))
            faces.append((a, b + 1, b))
    mat = material(name + "Mat", color=color, roughness=0.9, specular=0.2)
    return mesh_object(name, np.array(verts), np.array(faces)[:, ::-1], material=mat)


def game_environment(ground="#a3a5ab", ground_alt="#9a9ca2", sky="#6fbaff", sun_azimuth=-40.0):
    """A simple Roblox-like place: a big studded grey baseplate with 4-stud tiles, sky and a sun."""
    half = 150.0
    verts = np.array([(-half, -half, 0), (half, -half, 0), (half, half, 0), (-half, half, 0)])
    mat = bpy.data.materials.new("Ground")
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    bsdf = nodes["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = 0.9
    checker = nodes.new("ShaderNodeTexChecker")
    checker.inputs["Color1"].default_value = (*srgb(ground), 1)
    checker.inputs["Color2"].default_value = (*srgb(ground_alt), 1)
    checker.inputs["Scale"].default_value = 2 * half / 4.0
    coords = nodes.new("ShaderNodeTexCoord")
    mat.node_tree.links.new(coords.outputs["UV"], checker.inputs["Vector"])
    mat.node_tree.links.new(checker.outputs["Color"], bsdf.inputs["Base Color"])
    add_studs(mat, pitch=1.0, strength=0.6, distance=0.05, groove=0.12, attribute=None)
    obj = mesh_object("Ground", verts, np.array([(0, 1, 2), (0, 2, 3)]), material=mat)
    uv = obj.data.uv_layers.new(name="UV")
    corners = {0: (0, 0), 1: (1, 0), 2: (1, 1), 3: (0, 1)}
    for loop in obj.data.loops:
        uv.data[loop.index].uv = corners[loop.vertex_index]
    sun = bpy.data.lights.new("Sun", "SUN")
    sun.energy = 3.2
    sun.angle = math.radians(3)
    sun_obj = bpy.data.objects.new("Sun", sun)
    bpy.context.scene.collection.objects.link(sun_obj)
    sun_obj.rotation_euler = (math.radians(45), 0, math.radians(sun_azimuth))
    world(sky, strength=1.0)


def area_light(name, location, target, power, size, color="#ffffff", size_y=None):
    data = bpy.data.lights.new(name, "AREA")
    data.energy = power
    data.color = tuple(srgb(color))
    data.shape = "RECTANGLE" if size_y else "SQUARE"
    data.size = size
    if size_y:
        data.size_y = size_y
    obj = bpy.data.objects.new(name, data)
    bpy.context.scene.collection.objects.link(obj)
    obj.location = location
    look_at(obj, target)
    return obj


def look_at(obj, target):
    direction = Vector(target) - Vector(obj.location)
    obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def camera(name="Camera", lens=70):
    data = bpy.data.cameras.new(name)
    data.lens = lens
    data.sensor_width = 36
    obj = bpy.data.objects.new(name, data)
    bpy.context.scene.collection.objects.link(obj)
    bpy.context.scene.camera = obj
    return obj


def frame(cam, target, azimuth, elevation, distance):
    """Place `cam` around `target`. Azimuth 0 looks at the character's front (from -y)."""
    az = math.radians(azimuth)
    el = math.radians(elevation)
    offset = Vector((math.sin(az) * math.cos(el), -math.cos(az) * math.cos(el), math.sin(el))) * distance
    cam.location = Vector(target) + offset
    look_at(cam, target)


def fit_distance(points, target, azimuth, elevation, lens, aspect, fill=0.82, sensor=36.0):
    """Camera distance so `points` (N, 3) fill `fill` of the frame when framed as in `frame`."""
    az = math.radians(azimuth)
    el = math.radians(elevation)
    fwd = -np.array([math.sin(az) * math.cos(el), -math.cos(az) * math.cos(el), math.sin(el)])
    right = np.cross(fwd, [0, 0, 1])
    right /= np.linalg.norm(right)
    up = np.cross(right, fwd)
    rel = np.asarray(points) - np.asarray(target)
    half_w = sensor / 2 / lens
    half_h = half_w / aspect if aspect >= 1 else half_w
    if aspect < 1:
        half_w = half_w * aspect
    best = 0.0
    for d in np.linspace(2, 200, 2000):
        depth = d + rel @ fwd
        x = np.abs(rel @ right) / depth
        y = np.abs(rel @ up) / depth
        if x.max() <= half_w * fill and y.max() <= half_h * fill:
            best = d
            break
    return best


def setup_render(width, height, samples=128, exposure=0.0, look="AgX - Punchy"):
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = samples
    scene.cycles.use_adaptive_sampling = True
    scene.cycles.adaptive_threshold = 0.02
    scene.cycles.use_denoising = True
    scene.cycles.denoiser = "OPENIMAGEDENOISE"
    scene.cycles.max_bounces = 8
    scene.cycles.diffuse_bounces = 3
    scene.cycles.glossy_bounces = 3
    scene.cycles.transmission_bounces = 4
    scene.cycles.caustics_reflective = False
    scene.cycles.caustics_refractive = False
    scene.render.resolution_x = width
    scene.render.resolution_y = height
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGB"
    scene.view_settings.view_transform = "AgX"
    try:
        scene.view_settings.look = look
    except TypeError:
        pass
    scene.view_settings.exposure = exposure
    scene.render.threads_mode = "AUTO"


def world(color="#d9dce3", strength=0.35):
    w = bpy.data.worlds.new("World")
    w.use_nodes = True
    bg = w.node_tree.nodes["Background"]
    bg.inputs["Color"].default_value = (*srgb(color), 1)
    bg.inputs["Strength"].default_value = strength
    bpy.context.scene.world = w


def silhouette():
    """Turn the current scene into a black shape on white: no backdrop, lights or shading."""
    black = bpy.data.materials.new("Silhouette")
    black.use_nodes = True
    nodes = black.node_tree.nodes
    nodes.clear()
    out = nodes.new("ShaderNodeOutputMaterial")
    emit = nodes.new("ShaderNodeEmission")
    emit.inputs["Color"].default_value = (0, 0, 0, 1)
    black.node_tree.links.new(emit.outputs["Emission"], out.inputs["Surface"])
    for obj in bpy.context.scene.objects:
        if obj.type == "MESH" and obj.name.startswith("Cyclorama"):
            obj.hide_render = True
    bpy.context.view_layer.material_override = black
    world("#ffffff", strength=1.0)
    scene = bpy.context.scene
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"
    scene.cycles.samples = 16


def render(path):
    bpy.context.scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)
