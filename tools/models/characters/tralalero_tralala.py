"""Tralalero Tralala: the blue three-legged shark in sneakers, as a chunky toy-like Brainrot.

Art direction: a stylized game collectible, not an animal. Big simple forms, a blunt oversized
head on a short squat body, thick fins with rounded edges, bug eyes, chunky brows, a giant grin
with big teeth, thick simple legs and oversized sneakers. Everything must read at a distance.

Every part is a signed distance field (see ../sdf.py): the shark, fins and legs blend into one
surface; eyes, teeth, tongue, socks and sneakers are their own meshes for their own materials.

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
# Body: a squat, head-heavy shark with rounded-box sections, (y, top z, bottom z, half width)
# ---------------------------------------------------------------------------------------------

PROFILE = np.array(
    [
        (-2.80, 3.30, 3.30, 0.00),
        (-2.64, 3.92, 2.62, 0.82),
        (-2.32, 4.32, 2.20, 1.25),
        (-1.80, 4.54, 1.97, 1.46),
        (-1.10, 4.60, 1.88, 1.52),
        (-0.40, 4.50, 1.92, 1.44),
        (0.20, 4.27, 2.12, 1.16),
        (0.75, 4.00, 2.52, 0.76),
        (1.22, 3.80, 2.92, 0.45),
        (1.56, 3.70, 3.18, 0.28),
        (1.82, 3.62, 3.40, 0.00),
    ]
)

# The tail swings a little to the character's left so the pose is not stiff
SWAY = np.array([(-3.0, 0.0), (0.0, 0.0), (0.75, 0.05), (1.22, 0.12), (1.56, 0.19), (1.82, 0.24), (2.8, 0.42)])


def sway(y):
    return np.interp(y, SWAY[:, 0], SWAY[:, 1])


LOFT = Loft([(y, (top + bottom) / 2, hw, (top - bottom) / 2, sway(y)) for y, top, bottom, hw in PROFILE], exponent=3.0)
FACE_PLANE = -2.64


def BODY(p):  # noqa: N802 - reads like the shape it is
    """The lofted body with its snout sliced into a broad, rounded, flat face."""
    return smax(LOFT(p), -(p[..., 1] - FACE_PLANE), 0.17)


def spine(y):
    """Centre height and half height of the body at y."""
    _, cz, _, hh = LOFT.section(y)
    return cz, hh


# ---------------------------------------------------------------------------------------------
# Fins: broad, thick, simple shapes with rounded edges
# ---------------------------------------------------------------------------------------------

FIN = {"depth": 0.3, "round_": 0.045, "smooth": 8}

DORSAL = Blade(
    origin=(0, -0.55, 4.3),
    u_axis=(0, 1, 0),
    v_axis=(0, 0, 1),
    outline=[(-0.95, -0.35), (-0.58, 0.52), (0.0, 1.38), (0.6, 1.86), (0.9, 1.86), (0.76, 1.26), (0.7, 0.56), (1.0, -0.35)],
    thickness=0.19,
    edge=0.17,
    **FIN,
)

TAIL = Blade(
    origin=(sway(1.56), 1.56, 3.46),
    u_axis=(0.15, 1, 0),
    v_axis=(0, 0, 1),
    outline=[
        (-0.4, 0.34),
        (0.18, 1.08),
        (0.72, 1.72),
        (1.1, 1.9),
        (1.06, 1.36),
        (0.76, 0.48),
        (0.68, 0.02),
        (0.82, -0.56),
        (1.04, -1.12),
        (0.66, -1.1),
        (0.12, -0.46),
        (-0.4, -0.3),
    ],
    thickness=0.17,
    edge=0.15,
    **FIN,
)


def pectoral(side):
    return Blade(
        origin=(side * 1.25, -1.0, 2.62),
        u_axis=(side * 1.0, 0.35, -0.5),
        v_axis=(0, 1, 0.1),
        outline=[(-0.35, -0.55), (0.6, -0.55), (1.45, -0.15), (1.92, 0.34), (1.76, 0.78), (0.9, 0.78), (-0.35, 0.72)],
        thickness=0.16,
        edge=0.14,
        bend=0.1 * side,
        **FIN,
    )


PECTORALS = [pectoral(1), pectoral(-1)]

# ---------------------------------------------------------------------------------------------
# Face: bug eyes, chunky brows, a giant grin
# ---------------------------------------------------------------------------------------------

HEAD_CENTER = np.array([0.0, -1.7, 3.3])
EYE_RADIUS = 0.5


def _eyes():
    eyes = []
    for side in (1, -1):
        direction = normalize((side * 0.5, -0.72, 0.62))
        surface = sdf.surface_point(BODY, HEAD_CENTER, direction)
        n = sdf.gradient(BODY, surface[None])[0]
        centre = surface - n * 0.14
        # a slightly goofy gaze: the eyes look forward but not quite at the same spot
        gaze = normalize(n * 0.3 + np.array([-side * 0.1, -1.0, 0.1 if side > 0 else -0.02]))
        eyes.append({"side": side, "center": centre, "normal": n, "gaze": gaze})
    return eyes


EYES = _eyes()


def _socket(eye):
    """A blue rim that seats the back half of the eyeball in the head."""
    c, n = eye["center"], eye["normal"]

    def fn(p):
        shell = sphere(p, c, EYE_RADIUS + 0.06)
        front = (p - c) @ n + 0.02
        return smax(shell, front, 0.04)

    return fn


SOCKETS = [_socket(e) for e in EYES]


def _brow(eye):
    """A thick brow above each eye. The left one is raised high, the right one cocked down."""
    side = eye["side"]
    n = eye["normal"]
    up = normalize(np.array([0.0, 0.0, 1.0]) - n * n[2])
    out = normalize(side * np.cross(up, n))
    raised = side < 0
    pts = []
    for t in np.linspace(-0.72, 1, 4):
        height = EYE_RADIUS + 0.16 + (0.12 + 0.18 * (1 - t * t) if raised else 0.13 * t)
        target = eye["center"] + out * (t * EYE_RADIUS * 1.05) + up * height
        origin = eye["center"] - n * 0.6
        pts.append(sdf.surface_point(BODY, origin, target - origin))
    return np.array(pts)


BROWS = [_brow(e) for e in EYES]


def brows(p):
    """Fat eyebrow bands, sliced flat a fixed height above the head like slabs of clay."""
    d = None
    for pts in BROWS:
        di = capsule_chain(p, sdf.catmull_rom(pts, 5), np.interp(np.linspace(0, 1, 16), [0, 0.5, 1], [0.17, 0.22, 0.16]))
        d = di if d is None else np.minimum(d, di)
    return smax(d, BODY(p) - 0.16, 0.045)


MOUTH_CENTER = np.array([0.0, -1.55, 3.05])
MOUTH_S = np.linspace(-1.0, 1.0, 41)


def _mouth_curve():
    pts, normals = [], []
    for s in MOUTH_S:
        yaw = math.radians(60.0) * s
        pitch = math.radians(-23.0 + 22.0 * s * s)
        d = normalize((math.sin(yaw) * math.cos(pitch), -math.cos(yaw) * math.cos(pitch), math.sin(pitch)))
        p = sdf.surface_point(BODY, MOUTH_CENTER, d)
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
MOUTH_R = 0.3 * (1.0 - 0.72 * MOUTH_S**2) + 0.05


def mouth_cut(p):
    lips = capsule_chain(p, MOUTH_P - MOUTH_N * 0.04, MOUTH_R)
    cavity = capsule_chain(p, MOUTH_P - MOUTH_N * 0.34, MOUTH_R * 1.2)
    return smin(lips, cavity, 0.08)


def _gill(y, side):
    pts = []
    for t in np.linspace(-1, 1, 4):
        z = 3.3 + t * 0.4
        yy = y + 0.08 * (1 - t * t)
        cx, cz, w, h = LOFT.section(yy)
        d = normalize((side * 1.0, 0, (z - cz) / max(h, 0.3) * 0.8))
        pts.append(sdf.surface_point(BODY, (cx, yy, cz), d))
    return np.array(pts)


GILLS = [_gill(y, side) for side in (1, -1) for y in (-0.95, -0.66, -0.37)]


def gills(p):
    d = None
    for pts in GILLS:
        di = capsule_chain(p, sdf.catmull_rom(pts, 4), np.interp(np.linspace(0, 1, 13), [0, 0.5, 1], [0.04, 0.07, 0.04]))
        d = di if d is None else np.minimum(d, di)
    return d


# ---------------------------------------------------------------------------------------------
# Legs: thick and simple, no anatomy
# ---------------------------------------------------------------------------------------------

LEGS = [
    {"hip": (0.95, -1.05, 2.35), "ankle": (0.97, -1.0, 0.92), "yaw": 12.0},
    {"hip": (-0.95, -1.05, 2.35), "ankle": (-0.97, -1.0, 0.92), "yaw": -12.0},
    {"hip": (0.0, 0.72, 2.7), "ankle": (0.0, 0.74, 0.92), "yaw": 0.0},
]
for leg in LEGS:
    for key in ("hip", "ankle"):
        leg[key] = np.array(leg[key], dtype=np.float64)


def leg_fn(leg):
    def fn(p):
        return round_cone(p, leg["hip"], leg["ankle"], 0.42, 0.33)

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

_dorsal = sdf.bounded(DORSAL, (-0.4, -1.6, 3.8), (0.4, 0.6, 6.4))
_tail = sdf.bounded(TAIL, (-0.3, 1.0, 2.1), (0.9, 3.0, 5.6))
_pects = [sdf.bounded(f, (min(s * 0.8, s * 3.3), -1.8, 1.0), (max(s * 0.8, s * 3.3), 0.7, 3.2)) for f, s in zip(PECTORALS, (1, -1))]
_face_lo, _face_hi = (-1.8, -3.2, 1.9), (1.8, -0.8, 5.2)
_mouth = sdf.bounded(mouth_cut, _face_lo, _face_hi)
_sockets = [sdf.bounded(f, _face_lo, _face_hi) for f in SOCKETS]
_brows = sdf.bounded(brows, _face_lo, _face_hi)
_gills = sdf.bounded(gills, (-1.8, -1.4, 2.5), (1.8, 0.0, 4.2))
_legs = sdf.bounded(legs, (-1.5, -1.6, 0.4), (1.5, 1.4, 3.3))


def shark(p):
    """The shark without legs: body, fins and face."""
    d = BODY(p)
    d = smin(d, _dorsal(p), 0.2)
    d = smin(d, _tail(p), 0.16)
    for f in _pects:
        d = smin(d, f(p), 0.18)
    for f in _sockets:
        d = smin(d, f(p), 0.12)
    for e in EYES:
        d = carve(d, sphere(p, e["center"], EYE_RADIUS + 0.015), 0.02)
    d = smin(d, _brows(p), 0.06)
    d = carve(d, _mouth(p), 0.05)
    d = carve(d, _gills(p), 0.03)
    return d


def body(p):
    return smin(shark(p), _legs(p), 0.22)


BODY_BOX = ((-3.5, -3.0, 0.5), (3.5, 3.1, 6.35))

# ---------------------------------------------------------------------------------------------
# Teeth and tongue
# ---------------------------------------------------------------------------------------------


def _teeth():
    blades = []
    r0 = MOUTH_R[len(MOUTH_R) // 2]
    for row, count, span, inset in (("upper", 6, 0.66, 0.12), ("lower", 5, 0.52, 0.15)):
        for i in range(count):
            s = -span + 2 * span * i / (count - 1)
            j = int(round(np.interp(s, MOUTH_S, np.arange(len(MOUTH_S)))))
            p, n, t, u, r = MOUTH_P[j], MOUTH_N[j], MOUTH_T[j], MOUTH_U[j], MOUTH_R[j]
            scale = (r / r0) ** 0.5
            width = 0.3 * scale
            length = (0.3 if row == "upper" else 0.24) * scale
            sign = 1.0 if row == "upper" else -1.0
            base = p + u * sign * (r * 0.86) - n * inset
            blades.append(
                Blade(
                    origin=base,
                    u_axis=t,
                    v_axis=-u * sign,
                    # a chunky tooth with a rounded point (convex, so no smoothing is needed)
                    outline=[
                        (-width / 2, -0.07),
                        (width / 2, -0.07),
                        (width / 2, 0.0),
                        (width * 0.3, length * 0.6),
                        (width * 0.12, length * 0.93),
                        (0.0, length),
                        (-width * 0.12, length * 0.93),
                        (-width * 0.3, length * 0.6),
                        (-width / 2, 0.0),
                    ],
                    thickness=0.1 * scale,
                    edge=0.07,
                    depth=0.05,
                    round_=0.04,
                    smooth=0,
                )
            )
    return blades


TEETH = _teeth()


def teeth(p):
    d = None
    for b in TEETH:
        di = b(p)
        d = di if d is None else smin(d, di, 0.02)
    return d


TEETH_BOX = (tuple(MOUTH_P.min(axis=0) - 0.45), tuple(MOUTH_P.max(axis=0) + 0.45))

_mid = len(MOUTH_S) // 2
TONGUE_CENTER = MOUTH_P[_mid] - MOUTH_N[_mid] * 0.3 - MOUTH_U[_mid] * 0.16


def tongue(p):
    d = ellipsoid(p, TONGUE_CENTER, (0.42, 0.34, 0.14))
    return smax(d, (p - TONGUE_CENTER) @ MOUTH_N[_mid] - 0.2, 0.05)


TONGUE_BOX = (tuple(TONGUE_CENTER - 0.6), tuple(TONGUE_CENTER + 0.6))

# ---------------------------------------------------------------------------------------------
# Socks and oversized sneakers (one per leg)
# ---------------------------------------------------------------------------------------------

SOCK_TOP = 1.36


def sock_fn(leg_index):
    fn = LEG_FNS[leg_index]

    def sock(p):
        d = fn(p) - 0.04
        d = smax(d, p[..., 2] - SOCK_TOP, 0.03)
        cuff = smax(np.abs(p[..., 2] - (SOCK_TOP - 0.06)) - 0.08, fn(p) - 0.09, 0.05)
        return smin(d, cuff, 0.03)

    return sock


SOCK_FNS = [sock_fn(i) for i in range(3)]


def sock_box(i):
    a = LEGS[i]["ankle"]
    return (a[0] - 0.6, a[1] - 0.6, 0.3), (a[0] + 0.6, a[1] + 0.6, SOCK_TOP + 0.2)


FOOTPRINT = np.array(
    [
        (-0.30, 0.00),
        (-0.25, 0.21),
        (-0.05, 0.29),
        (0.35, 0.31),
        (0.72, 0.34),
        (1.00, 0.30),
        (1.15, 0.14),
        (1.17, -0.04),
        (1.07, -0.25),
        (0.75, -0.33),
        (0.35, -0.29),
        (-0.05, -0.28),
        (-0.25, -0.2),
    ]
)
SOLE_TOP = 0.25
SHOE_SCALE = 1.42


class Shoe:
    """A chunky toy sneaker built in its own frame: u forward from the heel, v across, z up."""

    def __init__(self, leg, mirror):
        self.ankle = leg["ankle"]
        yaw = math.radians(leg["yaw"])
        self.f = np.array([math.sin(yaw), -math.cos(yaw), 0.0])
        self.s = np.array([math.cos(yaw), math.sin(yaw), 0.0])
        self.mirror = mirror
        heel = self.ankle - self.f * 0.26 * SHOE_SCALE
        self.heel = np.array([heel[0], heel[1], 0.0])
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
        return 0.1 * smoothstep(0.6, 1.17, u) ** 2 + 0.03 * smoothstep(-0.05, -0.3, u) ** 2

    def sole(self, p):
        u, v, z = self.local(p)
        d2 = sdf.polygon2d(u, v, self.outline)
        zz = z - self.toe_spring(u)
        dz = np.abs(zz - SOLE_TOP / 2) - SOLE_TOP / 2
        r = 0.07
        ox, oz = np.maximum(d2 + r, 0), np.maximum(dz + r, 0)
        return (np.sqrt(ox * ox + oz * oz) + np.minimum(np.maximum(d2, dz) + r, 0) - r) * SHOE_SCALE

    def upper_shape(self, p):
        d, q = self.upper_local(p)
        return d * SHOE_SCALE, q

    def upper_local(self, p):
        u, v, z = self.local(p)
        q = np.stack([u, v, z], axis=-1)
        toe = ellipsoid(q, (0.86, 0.0, 0.3), (0.34, 0.31, 0.23))
        vamp = ellipsoid(q, (0.5, 0.0, 0.38), (0.46, 0.3, 0.33))
        heel = ellipsoid(q, (0.1, 0.0, 0.44), (0.35, 0.28, 0.38))
        d = smin(smin(toe, vamp, 0.24), heel, 0.24)
        d2 = sdf.polygon2d(u, v, self.outline)
        d = smax(d, d2 + 0.04, 0.08)
        d = smax(d, SOLE_TOP - 0.04 + self.toe_spring(u) - z, 0.03)
        return d, q

    def upper(self, p):
        d, q = self.upper_local(p)
        opening = ellipsoid(q, (0.24, 0.0, 0.9), (0.25, 0.23, 0.26))
        d = carve(d, opening, 0.05)
        return smin(d, self._collar(q), 0.06) * SHOE_SCALE

    def toe_cap_line(self, v, z):
        """Where the white toe cap starts (u): low at the sides, sweeping forward over the top."""
        return 0.66 + 0.95 * np.clip(z - SOLE_TOP, 0, None) - 0.12 * (v / 0.33) ** 2

    def _collar(self, q):
        # a fat padded ring around the ankle opening, higher at the heel
        c = np.array([0.24, 0.0, 0.72])
        rel = q - c
        tilt = normalize((0.34, 0.0, 1.0))
        h = rel @ tilt
        radial = rel - h[..., None] * tilt
        return np.sqrt((np.sqrt(np.sum(radial * radial, axis=-1)) - 0.23) ** 2 + h * h) - 0.085

    def tongue(self, p):
        u, v, z = self.local(p)
        q = np.stack([u, v, z], axis=-1)
        blade = Blade(
            origin=(0.44, 0.0, 0.64),
            u_axis=(0, 1, 0),
            v_axis=(-0.4, 0, 1),
            outline=[(-0.15, -0.2), (0.15, -0.2), (0.16, 0.14), (0.1, 0.24), (-0.1, 0.24), (-0.16, 0.14)],
            thickness=0.06,
            edge=0.035,
            depth=0.06,
            round_=0.025,
            smooth=6,
        )
        return blade(q) * SHOE_SCALE

    def _laces(self):
        """Three fat lace bars across the vamp, sitting on the upper's surface."""
        bars = []
        for u in (0.48, 0.63, 0.78):
            pts = []
            for v in (-0.17, 0.0, 0.17):
                top = self.world(u + (0.02 if v > 0 else 0.0), v, 1.3)
                hit = sdf.surface_point(lambda x: -self.upper_shape(x)[0], top, (0, 0, -1), far=0.9)
                pts.append(hit + np.array([0, 0, 0.02 * SHOE_SCALE]))
            bars.append(np.array(pts))
        return bars

    def lace_fn(self, p):
        d = None
        for pts in self.laces:
            di = capsule_chain(p, sdf.catmull_rom(pts, 4), np.full(9, 0.05 * SHOE_SCALE))
            d = di if d is None else np.minimum(d, di)
        return d

    def __call__(self, p):
        d = smin(self.sole(p), self.upper(p), 0.04)
        d = smin(d, self.tongue(p), 0.04)
        return np.minimum(d, self.lace_fn(p))

    def box(self):
        corners = np.array([self.world(u, v, 0) for u in (-0.4, 1.3) for v in (-0.45, 0.45)])
        lo = corners.min(axis=0) - 0.05
        hi = corners.max(axis=0) + 0.05
        return (lo[0], lo[1], -0.05), (hi[0], hi[1], 1.55)


SHOES = [Shoe(LEGS[0], mirror=False), Shoe(LEGS[1], mirror=True), Shoe(LEGS[2], mirror=False)]
