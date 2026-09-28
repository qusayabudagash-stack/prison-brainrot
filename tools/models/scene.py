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


def decimate(obj, ratio):
    """Collapse-decimate `obj` in place (keeps paint attributes), returning its triangle count."""
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


def eye_material(name, iris="#3a2a1c", iris_edge="#140c07", pupil_size=0.42, iris_size=0.72):
    """A glossy eyeball whose iris and pupil face the object's local +Z axis."""
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    bsdf = nodes["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = 0.12
    bsdf.inputs["Coat Weight"].default_value = 1.0
    bsdf.inputs["Coat Roughness"].default_value = 0.02
    coords = nodes.new("ShaderNodeTexCoord")
    sep = nodes.new("ShaderNodeSeparateXYZ")
    norm = nodes.new("ShaderNodeVectorMath")
    norm.operation = "NORMALIZE"
    links.new(coords.outputs["Object"], norm.inputs[0])
    links.new(norm.outputs["Vector"], sep.inputs[0])
    # cos(angle from the gaze axis) -> sclera / iris / pupil
    ramp = nodes.new("ShaderNodeValToRGB")
    cr = ramp.color_ramp
    cr.interpolation = "LINEAR"
    cos_iris = math.cos(math.asin(iris_size * 0.62))
    cos_pupil = math.cos(math.asin(pupil_size * 0.62))
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
    links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
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


def setup_render(width, height, samples=128, exposure=0.0):
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
        scene.view_settings.look = "AgX - Medium High Contrast"
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


def render(path):
    bpy.context.scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)
