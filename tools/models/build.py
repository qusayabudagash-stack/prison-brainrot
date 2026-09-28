"""Mesh a character's parts and render product shots with Blender (Cycles, CPU).

    python tools/models/build.py tralalero_tralala --quality final --views threequarter,front,side,thumbnail,scale

Meshes are cached in tools/models/.cache/ keyed by the geometry source, so recoloring a
character (its *_look.py module) re-renders without re-sculpting.
"""

from __future__ import annotations

import argparse
import hashlib
import importlib
import math
import sys
import time
from pathlib import Path

import numpy as np

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE / "characters"))

import scene  # noqa: E402
import sdf  # noqa: E402

CACHE = HERE / ".cache"

# Camera azimuth (0 = straight at the face), elevation, frame size, lens, fill
VIEWS = {
    "threequarter": {"azimuth": 38, "elevation": 11, "size": (1600, 1200), "lens": 70, "fill": 0.86},
    "front": {"azimuth": 0, "elevation": 7, "size": (1600, 1200), "lens": 70, "fill": 0.84},
    "side": {"azimuth": 90, "elevation": 5, "size": (1600, 1200), "lens": 70, "fill": 0.86},
    "back": {"azimuth": 150, "elevation": 14, "size": (1600, 1200), "lens": 70, "fill": 0.86},
    "thumbnail": {"azimuth": 30, "elevation": 12, "size": (1024, 1024), "lens": 85, "fill": 0.93},
    "face": {"azimuth": 28, "elevation": 8, "size": (1200, 900), "lens": 85, "fill": 0.9, "focus": ((-1.6, -3.7, 2.1), (1.6, -1.6, 4.4))},
    "shoes": {"azimuth": 30, "elevation": 14, "size": (1200, 900), "lens": 85, "fill": 0.9, "focus": ((-1.6, -2.4, -0.1), (1.6, 1.4, 1.2))},
    "scale": {"azimuth": 24, "elevation": 6, "size": (1600, 1000), "lens": 100, "fill": 0.86, "avatar": True},
}


def source_hash(*paths):
    h = hashlib.sha1()
    for p in paths:
        h.update(Path(p).read_bytes())
    return h.hexdigest()[:12]


def build_part(part, geometry_hash, quality, force=False):
    step = part["step"] * (2.2 if quality == "preview" else 1.0)
    path = CACHE / f"{part['name']}_{geometry_hash}_{step:.4f}.npz"
    if path.exists() and not force:
        data = np.load(path)
        return data["verts"], data["faces"], data["normals"]
    t0 = time.time()
    fn = part["fn"]
    verts, faces = sdf.mesh(fn, part["box"][0], part["box"][1], step)
    verts = sdf.project(fn, verts, iterations=2)
    normals = sdf.normals(fn, verts)
    CACHE.mkdir(exist_ok=True)
    np.savez_compressed(path, verts=verts, faces=faces, normals=normals)
    print(f"  meshed {part['name']}: {len(faces):,} tris in {time.time() - t0:.1f}s", flush=True)
    return verts, faces, normals


def surface_material():
    return scene.material(
        "Surface",
        vertex_color=True,
        attributes=("Roughness", "Coat Weight", "Subsurface Weight", "Sheen Weight"),
        coat_roughness=0.12,
    )


def uv_sphere(radius, segments=96, rings=48):
    verts = [(0, 0, radius)]
    for i in range(1, rings):
        th = math.pi * i / rings
        for j in range(segments):
            ph = 2 * math.pi * j / segments
            verts.append((radius * math.sin(th) * math.cos(ph), radius * math.sin(th) * math.sin(ph), radius * math.cos(th)))
    verts.append((0, 0, -radius))
    faces = []
    for j in range(segments):
        faces.append((0, 1 + j, 1 + (j + 1) % segments))
    for i in range(rings - 2):
        a0 = 1 + i * segments
        b0 = a0 + segments
        for j in range(segments):
            j1 = (j + 1) % segments
            faces.append((a0 + j, b0 + j, b0 + j1))
            faces.append((a0 + j, b0 + j1, a0 + j1))
    last = len(verts) - 1
    base = 1 + (rings - 2) * segments
    for j in range(segments):
        faces.append((base + j, last, base + (j + 1) % segments))
    verts = np.array(verts)
    faces = np.array(faces)
    return verts, faces[:, ::-1], verts / radius


def add_eyes(look, root):
    mat = scene.eye_material("Eye", **look.EYE_LOOK)
    for i, eye in enumerate(look.EYES):
        verts, faces, normals = uv_sphere(eye["radius"])
        obj = scene.mesh_object(f"Eye{i}", verts, faces, vertex_normals=normals, material=mat, parent=root)
        obj.location = tuple(eye["center"])
        gaze = eye["gaze"]
        from mathutils import Vector

        obj.rotation_mode = "QUATERNION"
        obj.rotation_quaternion = Vector(tuple(gaze)).to_track_quat("Z", "Y")


def avatar_parts():
    """A classic blocky 5-stud Roblox avatar (legs 2, torso 2, head 1) for scale."""

    def box(c, half, r):
        c = np.asarray(c)
        half = np.asarray(half)

        def fn(p):
            q = np.abs(p - c) - (half - r)
            return sdf.length(np.maximum(q, 0)) + np.minimum(np.max(q, axis=-1), 0) - r

        return fn

    def head(p):
        c = np.array([0, 0, 4.5])
        q = p - c
        radial = np.sqrt(q[..., 0] ** 2 + q[..., 1] ** 2) - 0.44
        vert = np.abs(q[..., 2]) - 0.36
        return np.sqrt(np.maximum(radial, 0) ** 2 + np.maximum(vert, 0) ** 2) + np.minimum(np.maximum(radial, vert), 0) - 0.14

    yellow = scene.srgb("#f5cd30")
    blue = scene.srgb("#0d69ac")
    green = scene.srgb("#a4bd47")

    def face(v, n):
        col = np.tile(yellow, (len(v), 1))
        front = v[:, 1] < -0.3
        for ex in (-0.17, 0.17):
            eye = ((v[:, 0] - ex) / 0.05) ** 2 + ((v[:, 2] - 4.62) / 0.1) ** 2 < 1
            col[front & eye] = scene.srgb("#141414")
        r = np.sqrt(v[:, 0] ** 2 + (v[:, 2] - 4.55) ** 2)
        smile = (np.abs(r - 0.26) < 0.025) & (v[:, 2] < 4.42) & front
        col[smile] = scene.srgb("#141414")
        return col

    parts = [
        ("AvatarHead", head, ((-0.7, -0.7, 3.9), (0.7, 0.7, 5.1)), face),
        ("AvatarTorso", box((0, 0, 3), (1, 0.5, 1), 0.06), ((-1.1, -0.6, 1.9), (1.1, 0.6, 4.1)), blue),
        ("AvatarArmR", box((1.5, 0, 3), (0.5, 0.5, 1), 0.06), ((0.9, -0.6, 1.9), (2.1, 0.6, 4.1)), yellow),
        ("AvatarArmL", box((-1.5, 0, 3), (0.5, 0.5, 1), 0.06), ((-2.1, -0.6, 1.9), (-0.9, 0.6, 4.1)), yellow),
        ("AvatarLegR", box((0.5, 0, 1), (0.5, 0.5, 1), 0.06), ((-0.1, -0.6, -0.1), (1.1, 0.6, 2.1)), green),
        ("AvatarLegL", box((-0.5, 0, 1), (0.5, 0.5, 1), 0.06), ((-1.1, -0.6, -0.1), (0.1, 0.6, 2.1)), green),
    ]
    return parts


def add_avatar(root, offset, facing=0.0):
    """Place the avatar at `offset`, turned `facing` degrees about z (0 faces -y, like characters)."""
    a = math.radians(facing)
    rot = np.array([[math.cos(a), -math.sin(a), 0], [math.sin(a), math.cos(a), 0], [0, 0, 1]])
    mat = scene.material("Avatar", vertex_color=True, roughness=0.45, coat=0.1)
    points = []
    for name, fn, box, paint in avatar_parts():
        verts, faces = sdf.mesh(fn, box[0], box[1], 0.02)
        verts = sdf.project(fn, verts, iterations=2)
        normals = sdf.normals(fn, verts)
        col = paint(verts, normals) if callable(paint) else np.tile(paint, (len(verts), 1))
        verts = verts @ rot.T + np.asarray(offset)
        normals = normals @ rot.T
        scene.mesh_object(name, verts, faces, vertex_normals=normals, colors=col, material=mat, parent=root)
        points.append(verts[:: max(1, len(verts) // 400)])
    return np.vstack(points)


def studio(azimuth, target, radius):
    """Backdrop and lights arranged around the camera direction, product-photo style."""
    cyc = scene.cyclorama(color="#e7ddd0", radius=8.0, depth=radius * 3.2 + 6)
    cyc.rotation_euler = (0, 0, math.radians(azimuth))

    def around(az, el, dist):
        a = math.radians(azimuth + az)
        e = math.radians(el)
        return (
            target[0] + math.sin(a) * math.cos(e) * dist,
            target[1] - math.cos(a) * math.cos(e) * dist,
            target[2] + math.sin(e) * dist,
        )

    s = radius / 3.5
    scene.area_light("Key", around(-42, 42, 12 * s), target, 2600 * s * s, 7 * s, color="#fff4e6")
    scene.area_light("Fill", around(55, 12, 12 * s), target, 700 * s * s, 9 * s, color="#e6efff")
    scene.area_light("Rim", around(165, 38, 10 * s), target, 1900 * s * s, 4 * s, color="#fff0dc")
    scene.area_light("Top", around(0, 85, 10 * s), target, 500 * s * s, 6 * s, color="#ffffff")
    # a soft glow on the backdrop behind the character, fading toward the edges
    wall = around(180, 12, radius * 3.2)
    glow = scene.area_light("Backdrop", around(180, 35, radius * 1.3), wall, 1400 * s * s, 4 * s, color="#fff6ec")
    glow.data.spread = math.radians(70)
    scene.world(color="#dfe3ea", strength=0.25)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("character")
    parser.add_argument("--quality", choices=("preview", "final"), default="preview")
    parser.add_argument("--views", default="threequarter")
    parser.add_argument("--out", default=None)
    parser.add_argument("--samples", type=int, default=None)
    parser.add_argument("--scale", type=float, default=None, help="resolution multiplier")
    parser.add_argument("--force", action="store_true")
    parser.add_argument("--decimate", type=int, default=None, help="preview at a game budget: total triangles")
    args = parser.parse_args()

    geometry = importlib.import_module(args.character)
    look = importlib.import_module(args.character + "_look")
    geometry_hash = source_hash(geometry.__file__, sdf.__file__)
    out = Path(args.out) if args.out else HERE.parents[1] / "assets" / "brainrots" / geometry.ID / "renders"
    out.mkdir(parents=True, exist_ok=True)

    t0 = time.time()
    meshes = []
    for part in look.PARTS:
        verts, faces, normals = build_part(part, geometry_hash, args.quality, args.force)
        meshes.append((part, verts, faces, normals))
    print(f"meshes ready in {time.time() - t0:.1f}s, {sum(len(m[2]) for m in meshes):,} tris", flush=True)

    painted = []
    for part, verts, faces, normals in meshes:
        col, attrs = part["paint"](verts, normals)
        painted.append((part, verts, faces, normals, col, attrs))

    all_points = np.vstack([m[1][:: max(1, len(m[1]) // 3000)] for m in meshes])
    lo = all_points.min(axis=0)
    hi = all_points.max(axis=0)
    for name in args.views.split(","):
        view = VIEWS[name]
        scene.reset()
        root = scene.empty("Character")
        mat = surface_material()
        total = sum(len(p[2]) for p in painted)
        for part, verts, faces, normals, col, attrs in painted:
            obj = scene.mesh_object(part["name"], verts, faces, vertex_normals=normals, colors=col, attributes=attrs, material=mat, parent=root)
            if args.decimate:
                scene.decimate(obj, args.decimate / total)
        add_eyes(look, root)
        points = all_points
        if view.get("avatar"):
            # side by side at the same depth from the camera, both facing it, so sizes compare fairly
            az = math.radians(view["azimuth"])
            right = np.array([math.cos(az), math.sin(az), 0.0])
            centre = np.array([(lo[0] + hi[0]) / 2, (lo[1] + hi[1]) / 2, 0.0])
            reach = float(np.max((all_points - centre) @ right))
            offset = centre + right * (reach + 0.6 + 2.0)
            points = np.vstack([points, add_avatar(root, offset, facing=view["azimuth"])])
        if view.get("focus"):
            flo, fhi = np.asarray(view["focus"][0]), np.asarray(view["focus"][1])
            points = all_points[np.all((all_points >= flo) & (all_points <= fhi), axis=1)]
        plo, phi = points.min(axis=0), points.max(axis=0)
        target = (plo + phi) / 2
        radius = float(np.linalg.norm(phi - plo) / 2)
        studio(view["azimuth"], target, radius)
        w, h = view["size"]
        if args.scale:
            w, h = int(w * args.scale), int(h * args.scale)
        cam = scene.camera(lens=view["lens"])
        dist = scene.fit_distance(points, target, view["azimuth"], view["elevation"], view["lens"], w / h, view["fill"])
        scene.frame(cam, target, view["azimuth"], view["elevation"], dist)
        samples = args.samples or (24 if args.quality == "preview" else 160)
        scene.setup_render(w, h, samples=samples)
        t1 = time.time()
        suffix = f"_{args.decimate // 1000}k" if args.decimate else ""
        path = out / f"{geometry.ID}_{name}{suffix}.png"
        scene.render(path)
        print(f"rendered {path.name} in {time.time() - t1:.1f}s", flush=True)


if __name__ == "__main__":
    main()
