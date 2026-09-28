"""Tralalero Tralala: the blue three-legged shark in sneakers.

Every part is sculpted as a signed distance field (see ../sdf.py): the shark body, fins, face
and legs blend into one continuous surface; socks, sneakers, teeth and eyes are their own
meshes so they get their own materials. Paint is computed per vertex from the same fields.

Coordinates: x right, y back (the character faces -y), z up, 1 unit = 1 Roblox stud.
"""

from __future__ import annotations

import math
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import sdf  # noqa: E402
from sdf import Blade, Loft, capsule_chain, carve, ellipsoid, normalize, round_cone, smax, smin, smoothstep, sphere  # noqa: E402

ID = "TralaleroTralala"

# ---------------------------------------------------------------------------------------------
# Body: a lofted shark silhouette, (y, top z, bottom z, half width) along the spine
# ---------------------------------------------------------------------------------------------

PROFILE = np.array(
    [
        (-3.52, 2.80, 2.80, 0.00),
        (-3.32, 3.16, 2.48, 0.52),
        (-2.98, 3.48, 2.10, 0.90),
        (-2.48, 3.74, 1.82, 1.13),
        (-1.80, 3.88, 1.67, 1.24),
        (-1.00, 3.90, 1.64, 1.25),
        (-0.36, 3.83, 1.70, 1.17),
        (0.28, 3.68, 1.88, 0.98),
        (0.88, 3.48, 2.22, 0.69),
        (1.44, 3.32, 2.58, 0.41),
        (1.92, 3.23, 2.86, 0.23),
        (2.28, 3.20, 3.01, 0.14),
        (2.52, 3.12, 3.12, 0.00),
    ]
)

# The tail sweeps gently to the character's left so the pose is not stiff
SWAY = np.array([(-3.6, 0.0), (0.0, 0.0), (0.28, 0.015), (0.88, 0.06), (1.44, 0.12), (1.92, 0.19), (2.28, 0.245), (2.52, 0.28), (3.4, 0.44)])


def sway(y):
    return np.interp(y, SWAY[:, 0], SWAY[:, 1])


BODY = Loft([(y, (top + bottom) / 2, hw, (top - bottom) / 2, sway(y)) for y, top, bottom, hw in PROFILE])


def spine(y):
    """Centre height and half height of the body at y."""
    _, cz, _, hh = BODY.section(y)
    return cz, hh


# ---------------------------------------------------------------------------------------------
# Fins
# ---------------------------------------------------------------------------------------------

DORSAL = Blade(
    origin=(0, -0.64, 3.66),
    u_axis=(0, 1, 0),
    v_axis=(0, 0, 1),
    outline=[
        (-0.80, -0.40),
        (-0.62, 0.30),
        (-0.30, 0.88),
        (0.12, 1.34),
        (0.52, 1.62),
        (0.80, 1.74),
        (0.74, 1.50),
        (0.56, 1.06),
        (0.52, 0.62),
        (0.66, 0.18),
        (0.95, -0.40),
    ],
    thickness=0.17,
    edge=0.022,
    depth=0.5,
)

TAIL = Blade(
    origin=(sway(2.18), 2.18, 3.11),
    u_axis=(0.17, 1, 0),
    v_axis=(0, 0, 1),
    outline=[
        (-0.30, 0.24),
        (0.16, 0.72),
        (0.56, 1.24),
        (0.90, 1.62),
        (0.84, 1.24),
        (0.66, 0.66),
        (0.56, 0.06),
        (0.66, -0.44),
        (0.80, -0.80),
        (0.50, -0.58),
        (0.12, -0.26),
        (-0.30, -0.20),
    ],
    thickness=0.15,
    edge=0.02,
    depth=0.42,
)

DORSAL2 = Blade(
    origin=(sway(1.44), 1.44, 3.32),
    u_axis=(0.12, 1, 0),
    v_axis=(0, 0, 1),
    outline=[(-0.26, -0.12), (-0.06, 0.18), (0.16, 0.34), (0.20, 0.20), (0.30, -0.12)],
    thickness=0.07,
    edge=0.015,
    depth=0.18,
)

ANAL = Blade(
    origin=(sway(1.48), 1.48, 2.62),
    u_axis=(0.12, 1, 0),
    v_axis=(0, 0, -1),
    outline=[(-0.26, -0.12), (-0.06, 0.16), (0.16, 0.30), (0.20, 0.17), (0.30, -0.12)],
    thickness=0.07,
    edge=0.015,
    depth=0.18,
)


def pectoral(side):
    return Blade(
        origin=(side * 0.98, -1.42, 2.27),
        u_axis=(side * 1.0, 0.30, -0.42),
        v_axis=(0, 1, 0.1),
        outline=[
            (-0.30, -0.42),
            (0.30, -0.40),
            (0.90, -0.16),
            (1.36, 0.22),
            (1.62, 0.56),
            (1.40, 0.60),
            (0.90, 0.52),
            (0.40, 0.52),
            (-0.30, 0.56),
        ],
        thickness=0.12,
        edge=0.02,
        depth=0.42,
        bend=0.14 * side,
    )


PECTORALS = [pectoral(1), pectoral(-1)]

# ---------------------------------------------------------------------------------------------
# Face
# ---------------------------------------------------------------------------------------------

HEAD_CENTER = np.array([0.0, -2.2, 2.72])
EYE_RADIUS = 0.36


def _face_layout():
    """Eye centres and gaze directions, found on the body surface."""
    eyes = []
    for side in (1, -1):
        direction = normalize((side * 0.84, -0.46, 0.34))
        surface = sdf.surface_point(BODY, HEAD_CENTER, direction)
        n = sdf.gradient(BODY, surface[None])[0]
        centre = surface - n * 0.12
        gaze = normalize(n * 0.45 + np.array([0, -1.0, 0.02]) + np.array([side * 0.10, 0, 0]))
        eyes.append({"side": side, "center": centre, "normal": n, "gaze": gaze})
    return eyes


EYES = _face_layout()


def _lid(eye):
    """A skin cap over the top of the eyeball, tilted down toward the snout for a cocky look."""
    side = eye["side"]
    c = eye["center"]
    m = normalize((-side * 0.52, -0.2, 1.0))
    offset = EYE_RADIUS * 0.3

    def fn(p):
        shell = sphere(p, c, EYE_RADIUS + 0.035)
        plane = offset - (p - c) @ m
        return smax(shell, plane, 0.03)

    return fn


LIDS = [_lid(e) for e in EYES]


def _head_with_lids(p):
    d = BODY(p)
    for f in LIDS:
        d = smin(d, f(p), 0.09)
    return d


def _brow(eye):
    """A thick brow above the lid: low at the inner end, arched, raised at the outer end."""
    side = eye["side"]
    n = eye["normal"]
    up = np.array([0.0, 0.0, 1.0]) - n * n[2]
    up = normalize(up)
    out = normalize(side * np.cross(up, n))
    pts = []
    for t in np.linspace(-1, 1, 5):
        h = EYE_RADIUS * 1.0 + 0.10 * t + 0.06 * (1 - t * t)
        target = eye["center"] + out * (t * EYE_RADIUS * 1.0) + up * h
        origin = eye["center"] - n * 0.25
        pts.append(sdf.surface_point(_head_with_lids, origin, target - origin) - n * 0.015)
    return np.array(pts), [0.07, 0.09, 0.085, 0.07, 0.045]


BROWS = [_brow(e) for e in EYES]


def brows(p):
    d = None
    for pts, radii in BROWS:
        di = capsule_chain(p, sdf.catmull_rom(pts, 4), np.interp(np.linspace(0, 1, 17), np.linspace(0, 1, 5), radii))
        d = di if d is None else np.minimum(d, di)
    return d


# The grin: a crescent across the front of the head whose corners curl up toward the eyes
MOUTH_S = np.linspace(-1.0, 1.0, 41)


def _mouth_curve():
    pts, normals = [], []
    for s in MOUTH_S:
        yaw = math.radians(70.0) * s
        pitch = math.radians(-17.0 + 19.0 * s * s)
        d = normalize((math.sin(yaw) * math.cos(pitch), -math.cos(yaw) * math.cos(pitch), math.sin(pitch)))
        p = sdf.surface_point(BODY, HEAD_CENTER, d)
        pts.append(p)
        normals.append(sdf.gradient(BODY, p[None])[0])
    pts = np.array(pts)
    normals = np.array(normals)
    tangents = np.gradient(pts, axis=0)
    tangents /= np.linalg.norm(tangents, axis=1, keepdims=True)
    ups = np.cross(normals, tangents)
    ups /= np.linalg.norm(ups, axis=1, keepdims=True)
    return pts, normals, tangents, ups


MOUTH_P, MOUTH_N, MOUTH_T, MOUTH_U = _mouth_curve()
MOUTH_R = 0.15 * (1.0 - 0.78 * MOUTH_S**2) + 0.02


def mouth_cut(p):
    groove = capsule_chain(p, MOUTH_P - MOUTH_N * 0.03, MOUTH_R)
    cavity = capsule_chain(p, MOUTH_P - MOUTH_N * 0.22, MOUTH_R * 1.25)
    return smin(groove, cavity, 0.05)


def _gill(y, side):
    pts = []
    for t in np.linspace(-1, 1, 5):
        z = 2.68 + t * 0.32
        yy = y + 0.07 * (1 - t * t) - 0.02 * t
        c, hh = spine(yy)
        # place on the body surface by casting from the spine outward
        d = normalize((side * 1.0, 0, (z - c) / max(hh, 0.3)))
        pts.append(sdf.surface_point(BODY, (0, yy, c), d))
    return np.array(pts)


GILLS = [_gill(y, side) for side in (1, -1) for y in (-1.92, -1.68, -1.44)]


def gills(p):
    d = None
    for pts in GILLS:
        di = capsule_chain(p, pts, [0.018, 0.034, 0.04, 0.034, 0.018])
        d = di if d is None else np.minimum(d, di)
    return d


NOSTRILS = [sdf.surface_point(BODY, HEAD_CENTER, normalize((side * 0.2, -1.0, 0.16))) for side in (1, -1)]


def nostrils(p):
    d = None
    for c in NOSTRILS:
        di = ellipsoid(p, c, (0.045, 0.06, 0.03))
        d = di if d is None else np.minimum(d, di)
    return d


# ---------------------------------------------------------------------------------------------
# Legs
# ---------------------------------------------------------------------------------------------

LEGS = [
    {"hip": (0.64, -1.30, 2.08), "knee": (0.72, -1.36, 1.32), "ankle": (0.76, -1.26, 0.64), "yaw": 8.0},
    {"hip": (-0.64, -1.30, 2.08), "knee": (-0.72, -1.36, 1.32), "ankle": (-0.76, -1.26, 0.64), "yaw": -8.0},
    {"hip": (0.0, 0.62, 2.22), "knee": (0.0, 0.58, 1.34), "ankle": (0.0, 0.66, 0.64), "yaw": 0.0},
]
for leg in LEGS:
    for key in ("hip", "knee", "ankle"):
        leg[key] = np.array(leg[key], dtype=np.float64)


def leg_fn(leg):
    hip, knee, ankle = leg["hip"], leg["knee"], leg["ankle"]
    calf_c = knee + (ankle - knee) * 0.28 + np.array([0, 0.07, 0])
    knee_c = knee + np.array([0, -0.12, 0.02])

    def fn(p):
        thigh = round_cone(p, hip, knee, 0.43, 0.26)
        shin = round_cone(p, knee, ankle, 0.25, 0.155)
        calf = ellipsoid(p, calf_c, (0.25, 0.24, 0.34))
        kneecap = ellipsoid(p, knee_c, (0.14, 0.09, 0.13))
        d = smin(thigh, shin, 0.08)
        d = smin(d, calf, 0.14)
        return smin(d, kneecap, 0.06)

    return fn


LEG_FNS = [leg_fn(leg) for leg in LEGS]


def legs(p):
    d = None
    for fn in LEG_FNS:
        di = fn(p)
        d = di if d is None else np.minimum(d, di)
    return d


# ---------------------------------------------------------------------------------------------
# The complete body field
# ---------------------------------------------------------------------------------------------

_dorsal = sdf.bounded(DORSAL, (-0.3, -1.6, 3.0), (0.3, 0.4, 5.5))
_tail = sdf.bounded(TAIL, (-0.2, 1.7, 2.1), (0.8, 3.2, 4.9))
_dorsal2 = sdf.bounded(DORSAL2, (-0.1, 1.1, 3.1), (0.4, 1.9, 3.8))
_anal = sdf.bounded(ANAL, (-0.1, 1.1, 2.1), (0.4, 1.9, 2.9))
_pects = [sdf.bounded(f, (min(s * 0.6, s * 2.8), -2.0, 1.0), (max(s * 0.6, s * 2.8), 0.2, 2.8)) for f, s in zip(PECTORALS, (1, -1))]
_face_lo, _face_hi = (-1.45, -3.9, 1.7), (1.45, -1.2, 4.2)
_mouth = sdf.bounded(mouth_cut, _face_lo, _face_hi)
_lids = [sdf.bounded(f, _face_lo, _face_hi) for f in LIDS]
_brows = sdf.bounded(brows, _face_lo, _face_hi)
_gills = sdf.bounded(gills, (-1.4, -2.3, 2.0), (1.4, -1.1, 3.3))
_nostrils = sdf.bounded(nostrils, (-0.6, -3.8, 2.5), (0.6, -3.0, 3.2))
_legs = sdf.bounded(legs, (-1.3, -1.95, 0.3), (1.3, 1.2, 2.7))


def shark(p):
    """The shark without legs: body, fins and face."""
    d = BODY(p)
    d = smin(d, _dorsal(p), 0.17)
    d = smin(d, _tail(p), 0.12)
    d = smin(d, _dorsal2(p), 0.07)
    d = smin(d, _anal(p), 0.07)
    for f in _pects:
        d = smin(d, f(p), 0.15)
    for e in EYES:
        d = carve(d, sphere(p, e["center"], EYE_RADIUS + 0.02), 0.045)
    for f in _lids:
        d = smin(d, f(p), 0.09)
    d = smin(d, _brows(p), 0.07)
    d = carve(d, _mouth(p), 0.03)
    d = carve(d, _gills(p), 0.02)
    d = carve(d, _nostrils(p), 0.02)
    return d


def body(p):
    return smin(shark(p), _legs(p), 0.17)


BODY_BOX = ((-2.75, -3.8, 0.35), (2.75, 3.35, 5.55))

# ---------------------------------------------------------------------------------------------
# Teeth
# ---------------------------------------------------------------------------------------------


def _teeth():
    blades = []
    r0 = MOUTH_R[len(MOUTH_R) // 2]
    for row, count, inset in (("upper", 11, 0.035), ("lower", 9, 0.06)):
        for i in range(count):
            if row == "upper":
                s = -0.76 + 1.52 * i / (count - 1)
            else:
                s = -0.64 + 1.28 * i / (count - 1)
            k = np.interp(s, MOUTH_S, np.arange(len(MOUTH_S)))
            j = int(round(k))
            p, n, t, u, r = MOUTH_P[j], MOUTH_N[j], MOUTH_T[j], MOUTH_U[j], MOUTH_R[j]
            scale = (r / r0) ** 0.8
            width = 0.12 * scale
            length = (0.19 if row == "upper" else 0.16) * scale
            sign = 1.0 if row == "upper" else -1.0
            base = p + u * sign * (r * 0.9) - n * inset
            blades.append(
                Blade(
                    origin=base,
                    u_axis=t,
                    v_axis=-u * sign,
                    outline=[(-width / 2, -0.08), (width / 2, -0.08), (width / 2, 0.0), (0.0, length), (-width / 2, 0.0)],
                    thickness=0.034 * scale,
                    edge=0.012,
                    depth=0.05,
                    round_=0.01,
                    smooth=0,
                )
            )
    return blades


TEETH = _teeth()


def teeth(p):
    d = None
    for b in TEETH:
        di = b(p)
        d = di if d is None else smin(d, di, 0.012)
    return d


TEETH_BOX = (
    tuple(MOUTH_P.min(axis=0) - 0.3),
    tuple(MOUTH_P.max(axis=0) + 0.3),
)

# ---------------------------------------------------------------------------------------------
# Socks and sneakers (one per leg)
# ---------------------------------------------------------------------------------------------

SOCK_TOP = 1.02


def sock_fn(leg_index):
    fn = LEG_FNS[leg_index]
    leg = LEGS[leg_index]
    axis = normalize(leg["knee"] - leg["ankle"])
    ankle = leg["ankle"]

    def sock(p):
        rel = p - ankle
        # ribbing: fine vertical ribs around the leg
        radial = rel - (rel @ axis)[..., None] * axis
        ang = np.arctan2(radial[..., 0], radial[..., 1])
        ribs = 0.0045 * np.cos(ang * 26)
        d = fn(p) - 0.028 + ribs
        d = smax(d, p[..., 2] - SOCK_TOP, 0.02)
        cuff = smax(np.abs(p[..., 2] - (SOCK_TOP - 0.04)) - 0.055, fn(p) - 0.062, 0.035)
        return smin(d, cuff, 0.02)

    return sock


SOCK_FNS = [sock_fn(i) for i in range(3)]


def sock_box(i):
    a = LEGS[i]["ankle"]
    return (a[0] - 0.45, a[1] - 0.45, 0.2), (a[0] + 0.45, a[1] + 0.45, SOCK_TOP + 0.15)


FOOTPRINT = np.array(
    [
        (-0.30, 0.00),
        (-0.26, 0.19),
        (-0.08, 0.27),
        (0.30, 0.285),
        (0.66, 0.33),
        (0.96, 0.29),
        (1.13, 0.13),
        (1.16, -0.04),
        (1.05, -0.23),
        (0.74, -0.31),
        (0.34, -0.24),
        (-0.06, -0.25),
        (-0.26, -0.18),
    ]
)
SOLE_TOP = 0.21
SHOE_SCALE = 1.1


class Shoe:
    """A chunky sneaker built in its own frame: u forward from the heel, v across, z up."""

    def __init__(self, leg, mirror):
        self.ankle = leg["ankle"]
        yaw = math.radians(leg["yaw"])
        self.f = np.array([math.sin(yaw), -math.cos(yaw), 0.0])
        self.s = np.array([math.cos(yaw), math.sin(yaw), 0.0])
        self.mirror = mirror
        self.heel = self.ankle - self.f * 0.26 * SHOE_SCALE
        self.heel = np.array([self.heel[0], self.heel[1], 0.0])
        outline = FOOTPRINT.copy()
        if mirror:
            outline[:, 1] *= -1
        self.outline = sdf.smooth_outline(outline, 8)
        self.laces = self._laces()

    def local(self, p):
        """Shoe-frame coordinates, in unscaled shoe units."""
        q = (p - self.heel) / SHOE_SCALE
        return q @ self.f, q @ self.s, q[..., 2]

    def world(self, u, v, z):
        return self.heel + (self.f * u + self.s * v + np.array([0, 0, 1.0]) * z) * SHOE_SCALE

    def toe_spring(self, u):
        return 0.11 * smoothstep(0.55, 1.16, u) ** 2 + 0.035 * smoothstep(-0.05, -0.3, u) ** 2

    def sole(self, p):
        u, v, z = self.local(p)
        d2 = sdf.polygon2d(u, v, self.outline)
        zz = z - self.toe_spring(u)
        dz = np.abs(zz - SOLE_TOP / 2) - SOLE_TOP / 2
        r = 0.05
        ox, oz = np.maximum(d2 + r, 0), np.maximum(dz + r, 0)
        d = np.sqrt(ox * ox + oz * oz) + np.minimum(np.maximum(d2, dz) + r, 0) - r
        # the seam between outsole and midsole
        seam = np.sqrt(np.maximum(d2 + 0.0, 0) ** 2 + (zz - 0.07) ** 2) - 0.014
        return carve(d, seam, 0.008) * SHOE_SCALE

    def upper_shape(self, p):
        d, q = self.upper_local(p)
        return d * SHOE_SCALE, q

    def upper_local(self, p):
        u, v, z = self.local(p)
        q = np.stack([u, v, z], axis=-1)
        toe = ellipsoid(q, (0.86, 0.02 if not self.mirror else -0.02, 0.25), (0.34, 0.29, 0.2))
        vamp = ellipsoid(q, (0.50, 0.0, 0.34), (0.44, 0.285, 0.31))
        heel = ellipsoid(q, (0.10, 0.0, 0.40), (0.34, 0.265, 0.38))
        d = smin(smin(toe, vamp, 0.2), heel, 0.2)
        d2 = sdf.polygon2d(u, v, self.outline)
        d = smax(d, d2 + 0.03, 0.06)
        d = smax(d, SOLE_TOP - 0.03 + self.toe_spring(u) - z, 0.02)
        return d, q

    def upper(self, p):
        d, q = self.upper_local(p)
        opening = ellipsoid(q, (0.24, 0.0, 0.84), (0.23, 0.2, 0.26))
        d = carve(d, opening, 0.04)
        collar = self._collar(q)
        d = smin(d, collar, 0.05)
        # stitched seam around the toe cap
        seam = np.abs(q[..., 0] - self.toe_cap_line(q[..., 1], q[..., 2])) - 0.006
        d = carve(d, np.maximum(seam, np.abs(d) - 0.03) - 0.004, 0.006)
        return d * SHOE_SCALE

    def toe_cap_line(self, v, z):
        """Where the white toe cap starts (u): low at the sides, sweeping forward over the top."""
        return 0.66 + 0.95 * np.clip(z - SOLE_TOP, 0, None) - 0.12 * (v / 0.33) ** 2

    def _collar(self, q):
        # a padded ring around the ankle opening, higher at the heel
        c = np.array([0.24, 0.0, 0.66])
        rel = q - c
        tilt = normalize((0.34, 0.0, 1.0))
        h = rel @ tilt
        radial = rel - h[..., None] * tilt
        ring = np.sqrt((np.sqrt(np.sum(radial * radial, axis=-1)) - 0.205) ** 2 + h * h) - 0.07
        return ring

    def tongue(self, p):
        u, v, z = self.local(p)
        q = np.stack([u, v, z], axis=-1)
        blade = Blade(
            origin=(0.40, 0.0, 0.58),
            u_axis=(0, 1, 0),
            v_axis=(-0.35, 0, 1),
            outline=[(-0.13, -0.2), (0.13, -0.2), (0.14, 0.14), (0.08, 0.22), (-0.08, 0.22), (-0.14, 0.14)],
            thickness=0.045,
            edge=0.02,
            depth=0.06,
            round_=0.015,
            smooth=6,
        )
        return blade(q) * SHOE_SCALE

    def _laces(self):
        """Lace bars across the vamp, sitting on the upper's surface."""
        bars = []
        for i, u in enumerate((0.44, 0.56, 0.68, 0.80)):
            pts = []
            for v in (-0.16, 0.0, 0.16):
                top = self.world(u + (0.02 if v > 0 else 0.0), v, 1.2)
                hit = sdf.surface_point(lambda x: -self.upper_shape(x)[0], top, (0, 0, -1), far=0.75)
                pts.append(hit + np.array([0, 0, 0.012 * SHOE_SCALE]))
            bars.append(np.array(pts))
        return bars

    def lace_fn(self, p):
        d = None
        for pts in self.laces:
            di = capsule_chain(p, sdf.catmull_rom(pts, 4), np.full(9, 0.034 * SHOE_SCALE))
            d = di if d is None else np.minimum(d, di)
        return d

    def __call__(self, p):
        d = smin(self.sole(p), self.upper(p), 0.03)
        d = smin(d, self.tongue(p), 0.03)
        return np.minimum(d, self.lace_fn(p))

    def box(self):
        corners = [self.world(u, v, 0) for u in (-0.4, 1.3) for v in (-0.45, 0.45)]
        corners = np.array(corners)
        lo = corners.min(axis=0) - 0.05
        hi = corners.max(axis=0) + 0.05
        return (lo[0], lo[1], -0.05), (hi[0], hi[1], 1.1)


SHOES = [Shoe(LEGS[0], mirror=False), Shoe(LEGS[1], mirror=True), Shoe(LEGS[2], mirror=False)]
