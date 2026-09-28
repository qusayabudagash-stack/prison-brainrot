"""Signed distance field toolkit for sculpting characters in code.

Shapes are described as signed distance functions over numpy point arrays (..., 3): negative inside,
positive outside. They blend with smooth unions and carve with smooth subtractions, like clay, and a
marching-cubes pass turns the result into one continuous, seamless mesh.

Coordinates are Blender's: x right, y back (the character faces -y), z up, 1 unit = 1 Roblox stud.
"""

from __future__ import annotations

import numpy as np
from scipy.spatial import cKDTree
from skimage.measure import marching_cubes

# ---------------------------------------------------------------------------------------------
# Basics
# ---------------------------------------------------------------------------------------------


def length(v):
    return np.sqrt(np.sum(v * v, axis=-1))


def normalize(v):
    v = np.asarray(v, dtype=np.float64)
    return v / np.linalg.norm(v)


def smoothstep(a, b, x):
    t = np.clip((x - a) / (b - a), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def smin(a, b, k):
    """Polynomial smooth minimum: a union with a fillet of size k."""
    if k <= 0:
        return np.minimum(a, b)
    h = np.clip(0.5 + 0.5 * (b - a) / k, 0.0, 1.0)
    return b + (a - b) * h - k * h * (1.0 - h)


def smax(a, b, k):
    return -smin(-a, -b, k)


def carve(d, cut, k):
    """Smooth subtraction: remove `cut` from `d` with a rounded edge of size k."""
    return smax(d, -cut, k)


# ---------------------------------------------------------------------------------------------
# Primitives
# ---------------------------------------------------------------------------------------------


def sphere(p, c, r):
    return length(p - np.asarray(c)) - r


def ellipsoid(p, c, r, rotation=None):
    """Ellipsoid bound (Inigo Quilez). `rotation` is a 3x3 matrix whose rows are the local axes."""
    q = p - np.asarray(c)
    if rotation is not None:
        q = q @ np.asarray(rotation).T
    r = np.asarray(r, dtype=np.float64)
    k0 = length(q / r)
    k1 = length(q / (r * r))
    return k0 * (k0 - 1.0) / np.maximum(k1, 1e-9)


def superellipsoid(p, c, r, n=4.0):
    """A boxy ellipsoid: exponent 2 is an ellipsoid, higher values square it off (approximate)."""
    q = np.abs(p - np.asarray(c)) / np.asarray(r, dtype=np.float64)
    k0 = np.sum(q**n, axis=-1) ** (1.0 / n)
    return (k0 - 1.0) * float(np.min(r))


def rounded_box(p, c, half, radius):
    """An axis-aligned box with rounded edges (exact)."""
    q = np.abs(p - np.asarray(c)) - (np.asarray(half, dtype=np.float64) - radius)
    return length(np.maximum(q, 0.0)) + np.minimum(np.max(q, axis=-1), 0.0) - radius


def round_cone(p, a, b, r1, r2):
    """A capsule whose radius goes from r1 at a to r2 at b (exact, Inigo Quilez)."""
    a = np.asarray(a, dtype=np.float64)
    b = np.asarray(b, dtype=np.float64)
    ba = b - a
    l2 = float(ba @ ba)
    rr = r1 - r2
    a2 = l2 - rr * rr
    il2 = 1.0 / l2
    pa = p - a
    y = pa @ ba
    z = y - l2
    w = pa * l2 - y[..., None] * ba
    x2 = np.sum(w * w, axis=-1)
    y2 = y * y * l2
    z2 = z * z * l2
    k = np.sign(rr) * rr * rr * x2
    d_mid = (np.sqrt(np.maximum(x2 * a2 * il2, 0)) + y * rr) * il2 - r1
    d_b = np.sqrt(x2 + z2) * il2 - r2
    d_a = np.sqrt(x2 + y2) * il2 - r1
    return np.where(np.sign(z) * a2 * z2 > k, d_b, np.where(np.sign(y) * a2 * y2 < k, d_a, d_mid))


def capsule_chain(p, points, radii):
    """A smooth tapered tube through `points` (round cones joined end to end)."""
    d = None
    for i in range(len(points) - 1):
        di = round_cone(p, points[i], points[i + 1], radii[i], radii[i + 1])
        d = di if d is None else np.minimum(d, di)
    return d


def torus(p, c, axis, major, minor):
    q = p - np.asarray(c)
    axis = normalize(axis)
    h = q @ axis
    radial = q - h[..., None] * axis
    return np.sqrt((length(radial) - major) ** 2 + h * h) - minor


# ---------------------------------------------------------------------------------------------
# Splines and swept bodies
# ---------------------------------------------------------------------------------------------


def catmull_rom(points, samples_per_segment=16):
    """Dense samples along a Catmull-Rom spline through `points` (N, D). Returns (M, D)."""
    pts = np.asarray(points, dtype=np.float64)
    ext = np.vstack([pts[0] * 2 - pts[1], pts, pts[-1] * 2 - pts[-2]])
    out = []
    for i in range(1, len(ext) - 2):
        p0, p1, p2, p3 = ext[i - 1], ext[i], ext[i + 1], ext[i + 2]
        for s in range(samples_per_segment):
            t = s / samples_per_segment
            t2, t3 = t * t, t * t * t
            out.append(
                0.5
                * (2 * p1 + (p2 - p0) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (3 * p1 - p0 - 3 * p2 + p3) * t3)
            )
    out.append(pts[-1])
    return np.array(out)


class Sweep:
    """A body swept along a smooth centreline with an elliptical cross-section that changes along it.

    `sections` rows are (x, y, z, half_width, half_height): the centre of the section and the
    ellipse's half-width (across, along the local side axis) and half-height (along local up).
    The ends are closed with elliptical caps whose length is `cap` times the end radius.
    """

    def __init__(self, sections, up=(0, 0, 1), samples_per_segment=24, cap=1.0):
        rows = catmull_rom(np.asarray(sections, dtype=np.float64), samples_per_segment)
        self.c = rows[:, :3]
        self.w = np.maximum(rows[:, 3], 1e-3)
        self.h = np.maximum(rows[:, 4], 1e-3)
        n = len(self.c)
        tangents = np.gradient(self.c, axis=0)
        self.t = tangents / np.linalg.norm(tangents, axis=1, keepdims=True)
        up = normalize(up)
        side = np.cross(self.t, up)
        self.side = side / np.linalg.norm(side, axis=1, keepdims=True)
        self.up = np.cross(self.side, self.t)
        self.tree = cKDTree(self.c)
        self.n = n
        self.cap = cap

    def __call__(self, p):
        shape = p.shape[:-1]
        q = p.reshape(-1, 3)
        _, idx = self.tree.query(q, workers=-1)
        best_d = np.full(len(q), np.inf)
        best = None
        # Project onto the segment before and after the nearest sample, keep the closer one
        for offset in (-1, 0):
            i0 = np.clip(idx + offset, 0, self.n - 2)
            a = self.c[i0]
            b = self.c[i0 + 1]
            ab = b - a
            t = np.clip(np.sum((q - a) * ab, axis=1) / np.sum(ab * ab, axis=1), 0.0, 1.0)
            proj = a + ab * t[:, None]
            dist = np.linalg.norm(q - proj, axis=1)
            better = dist < best_d
            best_d = np.where(better, dist, best_d)
            if best is None:
                best = [i0.copy(), t.copy()]
            else:
                best[0] = np.where(better, i0, best[0])
                best[1] = np.where(better, t, best[1])
        i0, t = best
        c = self.c[i0] * (1 - t)[:, None] + self.c[i0 + 1] * t[:, None]
        tan = self.t[i0] * (1 - t)[:, None] + self.t[i0 + 1] * t[:, None]
        side = self.side[i0] * (1 - t)[:, None] + self.side[i0 + 1] * t[:, None]
        up = self.up[i0] * (1 - t)[:, None] + self.up[i0 + 1] * t[:, None]
        w = self.w[i0] * (1 - t) + self.w[i0 + 1] * t
        h = self.h[i0] * (1 - t) + self.h[i0 + 1] * t
        rel = q - c
        axial = np.sum(rel * tan, axis=1)
        lx = np.sum(rel * side, axis=1)
        lz = np.sum(rel * up, axis=1)
        # Only the two ends extend along the axis (closed with elliptical caps)
        at_start = (i0 == 0) & (t <= 0.0) & (axial < 0)
        at_end = (i0 == self.n - 2) & (t >= 1.0) & (axial > 0)
        cap_len = np.where(at_start, self.cap * min(self.w[0], self.h[0]), self.cap * min(self.w[-1], self.h[-1]))
        la = np.where(at_start | at_end, axial / cap_len, 0.0)
        k0 = np.sqrt((lx / w) ** 2 + (lz / h) ** 2 + la**2)
        d = (k0 - 1.0) * np.minimum(np.minimum(w, h), np.where(at_start | at_end, cap_len, np.inf))
        return d.reshape(shape)


class Loft:
    """A smooth body lofted through elliptical sections taken across the y axis.

    `sections` rows are (y, centre_z, half_width, half_height), sorted by y; the first and last
    rows should have zero size to close the ends. The sizes are interpolated with C2 cubic
    splines of their squares (which rounds the tips), so the surface has no creases or bands.
    Sections may be offset sideways with a centre_x column: rows (y, centre_z, hw, hh, centre_x).
    `exponent` above 2 squares the sections off into rounded boxes (a chunkier, toy-like body).
    """

    def __init__(self, sections, exponent=2.0):
        self.exponent = exponent
        from scipy.interpolate import CubicSpline

        rows = np.asarray(sections, dtype=np.float64)
        self.y0, self.y1 = rows[0, 0], rows[-1, 0]
        self.cz = CubicSpline(rows[:, 0], rows[:, 1], bc_type="natural")
        self.w2 = CubicSpline(rows[:, 0], rows[:, 2] ** 2, bc_type="natural")
        self.h2 = CubicSpline(rows[:, 0], rows[:, 3] ** 2, bc_type="natural")
        cx = rows[:, 4] if rows.shape[1] > 4 else np.zeros(len(rows))
        self.cx = CubicSpline(rows[:, 0], cx, bc_type="natural")
        self.tips = (
            np.array([self.cx(self.y0), self.y0, self.cz(self.y0)]),
            np.array([self.cx(self.y1), self.y1, self.cz(self.y1)]),
        )

    def section(self, y):
        """Centre x, centre z, half width and half height at y."""
        yc = np.clip(y, self.y0, self.y1)
        w = np.sqrt(np.maximum(self.w2(yc), 1e-6))
        h = np.sqrt(np.maximum(self.h2(yc), 1e-6))
        return self.cx(yc), self.cz(yc), w, h

    def __call__(self, p):
        x, y, z = p[..., 0], p[..., 1], p[..., 2]
        cx, cz, w, h = self.section(y)
        n = self.exponent
        k0 = (np.abs((x - cx) / w) ** n + np.abs((z - cz) / h) ** n) ** (1.0 / n)
        d = (k0 - 1.0) * np.minimum(w, h)
        before = y < self.y0
        after = y > self.y1
        if before.any():
            d = np.where(before, length(p - self.tips[0]), d)
        if after.any():
            d = np.where(after, length(p - self.tips[1]), d)
        return d


# ---------------------------------------------------------------------------------------------
# Flat shapes (fins, ears, shoe soles)
# ---------------------------------------------------------------------------------------------


def polygon2d(u, v, outline):
    """Signed distance to a closed 2D polygon (Inigo Quilez). `outline` is (N, 2)."""
    pts = np.asarray(outline, dtype=np.float64)
    d = (u - pts[0, 0]) ** 2 + (v - pts[0, 1]) ** 2
    s = np.ones_like(u)
    n = len(pts)
    j = n - 1
    for i in range(n):
        ex, ey = pts[j, 0] - pts[i, 0], pts[j, 1] - pts[i, 1]
        wx, wy = u - pts[i, 0], v - pts[i, 1]
        t = np.clip((wx * ex + wy * ey) / (ex * ex + ey * ey), 0.0, 1.0)
        bx, by = wx - ex * t, wy - ey * t
        d = np.minimum(d, bx * bx + by * by)
        c1 = v >= pts[i, 1]
        c2 = v < pts[j, 1]
        c3 = ex * wy > ey * wx
        flip = (c1 & c2 & c3) | (~c1 & ~c2 & ~c3)
        s = np.where(flip, -s, s)
        j = i
    return s * np.sqrt(d)


def smooth_outline(points, samples_per_segment=10):
    """A closed outline through `points`, smoothed with a closed Catmull-Rom spline."""
    pts = np.asarray(points, dtype=np.float64)
    n = len(pts)
    out = []
    for i in range(n):
        p0, p1, p2, p3 = pts[(i - 1) % n], pts[i], pts[(i + 1) % n], pts[(i + 2) % n]
        for s in range(samples_per_segment):
            t = s / samples_per_segment
            t2, t3 = t * t, t * t * t
            out.append(
                0.5
                * (2 * p1 + (p2 - p0) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (3 * p1 - p0 - 3 * p2 + p3) * t3)
            )
    return np.array(out)


class Blade:
    """A fin, ear or leaf: a flat outline in a plane, thickest in the middle and thin at its edges.

    The plane goes through `origin` with in-plane axes `u_axis` and `v_axis`; `outline` is in
    (u, v). `thickness` is the half-thickness in the middle, `edge` at the rim, reached `depth`
    in from the rim.
    """

    def __init__(self, origin, u_axis, v_axis, outline, thickness, edge=0.015, depth=0.4, round_=0.012, smooth=10, bend=0.0):
        self.o = np.asarray(origin, dtype=np.float64)
        self.u = normalize(u_axis)
        v = np.asarray(v_axis, dtype=np.float64)
        v = v - self.u * (v @ self.u)
        self.v = normalize(v)
        self.n = np.cross(self.u, self.v)
        self.outline = smooth_outline(outline, smooth) if smooth else np.asarray(outline)
        self.thickness = thickness
        self.edge = edge
        self.depth = depth
        self.round = round_
        self.bend = bend

    def __call__(self, p):
        q = p - self.o
        u = q @ self.u
        v = q @ self.v
        # `bend` curves the blade away from its normal toward the tip (+u), like a drooping fin
        w = q @ self.n + self.bend * np.maximum(u, 0.0) ** 2
        d2 = polygon2d(u, v, self.outline)
        half = self.edge + (self.thickness - self.edge) * np.sqrt(smoothstep(0.0, self.depth, -d2))
        dz = np.abs(w) - half
        ox, oz = np.maximum(d2 + self.round, 0), np.maximum(dz + self.round, 0)
        return np.sqrt(ox * ox + oz * oz) + np.minimum(np.maximum(d2, dz) + self.round, 0) - self.round


# ---------------------------------------------------------------------------------------------
# Meshing
# ---------------------------------------------------------------------------------------------


def evaluate(fn, pts, chunk=400_000):
    """Evaluate `fn` on a flat (N, 3) point list in chunks to bound memory."""
    out = np.empty(len(pts), dtype=np.float64)
    for start in range(0, len(pts), chunk):
        out[start : start + chunk] = fn(pts[start : start + chunk])
    return out


def bounded(fn, lo, hi, margin=0.3):
    """Skip `fn` for points far outside the box lo..hi, returning the box distance there instead.

    The box distance is a lower bound of the true distance, so unions stay correct as long as
    `margin` is larger than the blend radius used around the shape.
    """
    lo = np.asarray(lo, dtype=np.float64) - margin
    hi = np.asarray(hi, dtype=np.float64) + margin

    def wrapped(p):
        shape = p.shape[:-1]
        q = p.reshape(-1, 3)
        outside = np.maximum(np.maximum(lo - q, q - hi), 0.0)
        d = length(outside) + margin
        inside = np.all((q >= lo) & (q <= hi), axis=1)
        if inside.any():
            d[inside] = fn(q[inside])
        return d.reshape(shape)

    return wrapped


def mesh(fn, lo, hi, step, coarse=4):
    """Extract the zero surface of `fn` inside the box lo..hi at grid spacing `step`.

    The field is sampled on a coarse grid first and only evaluated exactly in the narrow band
    around the surface, so fine grids stay affordable. Returns (vertices (N, 3), faces (M, 3)).
    """
    from scipy.ndimage import zoom

    # offset the grid by an odd fraction of a cell so flat faces never sit exactly on grid planes
    # (marching cubes makes degenerate, flipped triangles there)
    lo = np.asarray(lo, dtype=np.float64) - step * np.array([0.371, 0.293, 0.417])
    hi = np.asarray(hi, dtype=np.float64)
    cstep = step * coarse
    ccounts = np.ceil((hi - lo) / cstep).astype(int) + 1
    axes = [lo[i] + np.arange(ccounts[i]) * cstep for i in range(3)]
    grid = np.stack(np.meshgrid(*axes, indexing="ij"), axis=-1).reshape(-1, 3)
    cvol = evaluate(fn, grid).reshape(ccounts).astype(np.float32)
    if cvol.min() > 0 or cvol.max() < 0:
        raise ValueError("surface not inside the meshing box")
    counts = (ccounts - 1) * coarse + 1
    vol = zoom(cvol, [(counts[i]) / ccounts[i] for i in range(3)], order=1, grid_mode=False)
    vol = vol[: counts[0], : counts[1], : counts[2]]
    # thin features (lips, fin edges) can hide between coarse samples, so keep the band generous
    band = cstep * 3.0
    idx = np.argwhere(np.abs(vol) < band)
    pts = lo + idx * step
    vol[idx[:, 0], idx[:, 1], idx[:, 2]] = evaluate(fn, pts)
    verts, faces, _, _ = marching_cubes(vol, level=0.0, spacing=(step, step, step))
    verts += lo
    return verts, faces


def project(fn, verts, iterations=3, eps=1e-3):
    """Pull mesh vertices exactly onto the zero surface (Newton steps along the field gradient)."""
    v = verts.copy()
    for _ in range(iterations):
        d = evaluate(fn, v)
        g = np.zeros_like(v)
        for i in range(3):
            e = np.zeros(3)
            e[i] = eps
            g[:, i] = (evaluate(fn, v + e) - evaluate(fn, v - e)) / (2 * eps)
        gg = np.maximum(np.sum(g * g, axis=1), 1e-6)
        stepv = (d / gg)[:, None] * g
        # Never move further than a grid cell: protects thin features from jumping across
        n = np.linalg.norm(stepv, axis=1, keepdims=True)
        stepv = np.where(n > 0.02, stepv * (0.02 / np.maximum(n, 1e-9)), stepv)
        v -= stepv
    return v


def normals(fn, verts, eps=1e-3):
    """Outward unit normals of the field at the vertices."""
    g = np.zeros_like(verts)
    for i in range(3):
        e = np.zeros(3)
        e[i] = eps
        g[:, i] = evaluate(fn, verts + e) - evaluate(fn, verts - e)
    return g / np.maximum(np.linalg.norm(g, axis=1, keepdims=True), 1e-12)


def occlusion(fn, verts, normals, steps=5, delta=0.06, strength=1.0):
    """Ambient occlusion from the field: how much the surroundings close in along the normal.

    Returns 1 for open surfaces, lower in creases and under overhangs.
    """
    occ = np.zeros(len(verts))
    weight = 1.0
    for i in range(1, steps + 1):
        h = delta * i
        occ += weight * np.maximum(h - evaluate(fn, verts + normals * h), 0.0) / h
        weight *= 0.6
    return np.clip(1.0 - strength * occ, 0.0, 1.0)


def surface_point(fn, origin, direction, far=6.0, steps=60):
    """Where a ray from `origin` (inside the shape) along `direction` leaves the surface."""
    origin = np.asarray(origin, dtype=np.float64)
    direction = normalize(direction)
    lo, hi = 0.0, far
    for _ in range(steps):
        mid = (lo + hi) / 2
        d = fn((origin + direction * mid)[None])[0]
        if d < 0:
            lo = mid
        else:
            hi = mid
    return origin + direction * lo


def gradient(fn, p, eps=1e-3):
    """Outward surface normal of `fn` at points p (N, 3)."""
    p = np.atleast_2d(p)
    g = np.zeros_like(p)
    for i in range(3):
        e = np.zeros(3)
        e[i] = eps
        g[:, i] = fn(p + e) - fn(p - e)
    return g / np.linalg.norm(g, axis=1, keepdims=True)
