"""Brick-built characters: turn a character's distance fields into a model made of studded bricks.

The design is sampled on a grid of cubic bricks (`size` studs each). Every brick face that shows
gets a raised, bevelled square stud, and each brick takes one flat colour from the character's
paint, so the result reads as a toy built from small studded blocks rather than a smooth sculpt.

Coordinates follow the rest of the pipeline: x right, y back, z up, 1 unit = 1 Roblox stud.
The grid is anchored at the origin so the bottom layer of bricks sits on z = 0.
"""

from __future__ import annotations

import numpy as np

import sdf

# The six face directions: (axis, sign)
DIRECTIONS = [(0, 1), (0, -1), (1, 1), (1, -1), (2, 1), (2, -1)]


def voxelize(fns, lo, hi, size, grow=0.3):
    """Sample the fields at brick centres.

    `fns` is a list of distance functions (one per part). A brick is solid where the nearest part's
    distance is below `grow` * size (a slight dilation so thin fins and teeth stay connected).
    Returns (origin, solid (nx, ny, nz) bool, owner (nx, ny, nz) int part index, distance).
    """
    lo = np.floor(np.asarray(lo, dtype=np.float64) / size) * size
    hi = np.ceil(np.asarray(hi, dtype=np.float64) / size) * size
    counts = np.round((hi - lo) / size).astype(int)
    axes = [lo[i] + (np.arange(counts[i]) + 0.5) * size for i in range(3)]
    centres = np.stack(np.meshgrid(*axes, indexing="ij"), axis=-1).reshape(-1, 3)
    dist = np.stack([sdf.evaluate(fn, centres) for fn in fns])
    owner = np.argmin(dist, axis=0)
    dmin = dist[owner, np.arange(len(centres))]
    solid = (dmin < grow * size).reshape(counts)
    return lo, solid, owner.reshape(counts), dmin.reshape(counts)


def exposed_faces(solid):
    """For each direction, a boolean grid of bricks whose face in that direction shows."""
    out = []
    for axis, sign in DIRECTIONS:
        neighbour = np.zeros_like(solid)
        src = [slice(None)] * 3
        dst = [slice(None)] * 3
        if sign > 0:
            src[axis] = slice(1, None)
            dst[axis] = slice(None, -1)
        else:
            src[axis] = slice(None, -1)
            dst[axis] = slice(1, None)
        neighbour[tuple(dst)] = solid[tuple(src)]
        out.append(solid & ~neighbour)
    return out


def brick_mesh(origin, size, solid, colors, stud=0.1, inset=0.13, top_inset=0.21):
    """Triangles for every visible brick face plus its raised square stud.

    `colors` is (nx, ny, nz, 3). Returns (verts, faces, colors per vertex, normals per vertex);
    vertices are not shared between faces so each face keeps its own flat colour and normal.
    """
    verts, cols, norms = [], [], []
    for (axis, sign), mask in zip(DIRECTIONS, exposed_faces(solid)):
        idx = np.argwhere(mask)
        if not len(idx):
            continue
        n = np.zeros(3)
        n[axis] = sign
        u = np.zeros(3)
        v = np.zeros(3)
        u[(axis + 1) % 3] = 1
        v[(axis + 2) % 3] = 1
        if sign < 0:
            u, v = v, u  # keep (u, v, n) right-handed so quads wind outward
        centre = origin + (idx + 0.5) * size + n * size / 2
        c = colors[idx[:, 0], idx[:, 1], idx[:, 2]]
        h = size / 2

        def quad(a, b, cc, d, normal):
            # two triangles a-b-c and a-c-d per brick face, corners kept together per triangle
            tris = np.stack([a, b, cc, a, cc, d], axis=1)  # (M, 6, 3)
            verts.append(tris.reshape(-1, 3))
            cols.append(np.repeat(c, 6, axis=0))
            norms.append(np.repeat(np.broadcast_to(normal, a.shape), 6, axis=0))

        def ring(offset, half):
            return [centre + n * offset + u * su * half + v * sv * half for su, sv in ((-1, -1), (1, -1), (1, 1), (-1, 1))]

        base = ring(0.0, h)
        quad(*base, n)
        bot = ring(0.0, h - inset * size)
        top = ring(stud * size, h - top_inset * size)
        quad(*top, n)
        for k in range(4):
            a, b = bot[k], bot[(k + 1) % 4]
            d, cc = top[k], top[(k + 1) % 4]
            side_n = np.cross(b - a, d - a)
            side_n /= np.linalg.norm(side_n, axis=1, keepdims=True)
            quad(a, b, cc, d, side_n)
    verts = np.concatenate(verts)
    cols = np.concatenate(cols)
    norms = np.concatenate(norms)
    faces = np.arange(len(verts)).reshape(-1, 3)
    # make sure every triangle winds outward
    a, b, c = verts[faces[:, 0]], verts[faces[:, 1]], verts[faces[:, 2]]
    flip = np.einsum("ij,ij->i", np.cross(b - a, c - a), norms[faces[:, 0]]) < 0
    faces[flip] = faces[flip][:, ::-1]
    return verts, faces, cols, norms


def surface_colors(fn, paint, centres, size):
    """Colour bricks from a smooth paint function: project each centre onto the part's surface."""
    n = sdf.normals(fn, centres, eps=size * 0.05)
    d = np.clip(sdf.evaluate(fn, centres), -size, size)
    points = centres - n * d[:, None]
    col, attrs = paint(points, n)
    return col, attrs, points, n
