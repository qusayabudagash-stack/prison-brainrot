"""Tralalero Tralala's paint and surface properties, computed per vertex from the geometry fields.

Kept apart from the geometry so recoloring does not invalidate the mesh cache.
"""

from __future__ import annotations

import numpy as np

import tralalero_tralala as g
import sdf
from sdf import smoothstep, sphere

from scene import mix, srgb

PAL = {
    "dorsal": srgb("#1f4fa8"),
    "blue": srgb("#3b82e4"),
    "blue_light": srgb("#7fb2f0"),
    "belly": srgb("#f3f1ec"),
    "fin_tip": srgb("#173d88"),
    "gum": srgb("#b9475e"),
    "mouth": srgb("#3e0d18"),
    "gill": srgb("#1b3c85"),
    "brow": srgb("#142a66"),
    "liner": srgb("#10214d"),
    "skin": srgb("#eab48e"),
    "skin_knee": srgb("#e8a488"),
    "white": srgb("#f6f5f1"),
    "sock_stripe": srgb("#2a5fd0"),
    "sock_stripe2": srgb("#e5484d"),
    "shoe": srgb("#2c6ce0"),
    "shoe_dark": srgb("#1a2f6b"),
    "outsole": srgb("#35363d"),
    "tooth": srgb("#fbfaf4"),
}


def surface(n, rough, coat=0.0, sss=0.0, sheen=0.0):
    ones = np.ones(n)
    return {
        "Roughness": ones * rough,
        "CoatWeight": ones * coat,
        "SubsurfaceWeight": ones * sss,
        "SheenWeight": ones * sheen,
    }


def blend(attrs, other, t):
    for key in attrs:
        attrs[key] = attrs[key] * (1 - t) + other[key] * t


def paint_body(v, n):
    count = len(v)
    y, z = v[:, 1], v[:, 2]
    centre, half = g.spine(y)
    t = (z - centre) / np.maximum(half, 0.2)

    # Countershading: blue back, white belly, with a soft wavy line along the flank that runs
    # into the grin so the upper jaw stays blue and the lower jaw is white
    line = np.interp(y, [-3.5, -2.6, -1.8, -0.5, 0.6, 1.6, 2.5], [-0.2, -0.3, -0.34, -0.28, -0.18, -0.02, 0.1])
    line = line + 0.05 * np.sin(y * 2.6 + 0.4)
    belly = smoothstep(line + 0.05, line - 0.05, t)
    rel = v - g.HEAD_CENTER
    yaw = np.degrees(np.arctan2(rel[:, 0], -rel[:, 1])) / 70.0
    mouth_z = np.interp(np.clip(yaw, -1, 1), g.MOUTH_S, g.MOUTH_P[:, 2])
    mouth_r = np.interp(np.clip(yaw, -1, 1), g.MOUTH_S, g.MOUTH_R)
    corner = np.clip(np.abs(yaw) - 1.0, 0, None)
    jaw_line = mouth_z - mouth_r * 0.2 - corner * 0.6
    jaw = smoothstep(jaw_line + 0.03, jaw_line - 0.03, z)
    head = smoothstep(-1.75, -2.35, y) * (rel[:, 1] < 0.4)
    belly = belly * (1 - head) + jaw * head
    back = smoothstep(-0.1, 0.95, t)
    col = mix(PAL["blue"], PAL["dorsal"], back * 0.9)
    col = mix(col, PAL["belly"], belly)
    attrs = surface(count, 0.38, coat=0.22, sss=0.03)

    # Fins stay blue all over, lighter underneath, darker toward their tips
    fin = np.minimum.reduce([f(v) for f in g._pects] + [g._tail(v), g._dorsal(v), g._anal(v), g._dorsal2(v)])
    on_fin = smoothstep(0.08, 0.0, fin) * smoothstep(-0.02, 0.1, g.BODY(v))
    under = smoothstep(0.1, -0.6, n[:, 2]) * 0.35
    fin_col = mix(PAL["blue"], PAL["blue_light"], under)
    col = mix(col, fin_col, on_fin)
    tip = smoothstep(0.45, 1.35, g.BODY(v))
    col = mix(col, PAL["fin_tip"], tip * 0.75)

    # Face details
    brow = smoothstep(0.05, 0.02, g._brows(v))
    col = mix(col, PAL["brow"], brow)
    socket = np.min([sphere(v, e["center"], g.EYE_RADIUS + 0.02) for e in g.EYES], axis=0)
    col = mix(col, PAL["liner"], smoothstep(0.035, 0.008, socket))
    gill = smoothstep(0.02, 0.0, g._gills(v))
    col = mix(col, PAL["gill"], gill)
    nostril = smoothstep(0.02, 0.0, g._nostrils(v))
    col = mix(col, PAL["mouth"], nostril * 0.8)

    mouth = smoothstep(0.03, 0.004, g._mouth(v))
    depth = smoothstep(0.03, 0.12, -g.BODY(v))
    mouth_col = mix(PAL["gum"], PAL["mouth"], depth)
    col = mix(col, mouth_col, mouth)
    blend(attrs, surface(count, 0.22, coat=0.8, sss=0.25), mouth)

    # Legs: warm skin, pinker knees
    skin = smoothstep(0.035, -0.035, g._legs(v) - g.shark(v))
    knee = np.zeros(count)
    for leg in g.LEGS:
        knee = np.maximum(knee, smoothstep(0.3, 0.05, np.linalg.norm(v - (leg["knee"] + [0, -0.12, 0]), axis=1)))
    skin_col = mix(PAL["skin"], PAL["skin_knee"], knee * 0.6)
    col = mix(col, skin_col, skin)
    blend(attrs, surface(count, 0.5, coat=0.05, sss=0.35), skin)
    return col, attrs


def paint_teeth(v, n):
    col = np.tile(PAL["tooth"], (len(v), 1))
    return col, surface(len(v), 0.2, coat=0.6, sss=0.2)


def paint_sock(i):
    def fn(v, n):
        z = v[:, 2]
        top = g.SOCK_TOP
        col = np.tile(PAL["white"], (len(v), 1))
        s1 = smoothstep(0.006, -0.006, np.abs(z - (top - 0.19)) - 0.03)
        s2 = smoothstep(0.006, -0.006, np.abs(z - (top - 0.29)) - 0.03)
        col = mix(col, PAL["sock_stripe"], s1)
        col = mix(col, PAL["sock_stripe2"], s2)
        return col, surface(len(v), 0.85, sheen=0.8, sss=0.1)

    return fn


def paint_shoe(i):
    shoe = g.SHOES[i]

    def fn(v, n):
        count = len(v)
        u, _, z = shoe.local(v)
        col = np.tile(PAL["shoe"], (count, 1))
        attrs = surface(count, 0.42, coat=0.25)

        # White toe cap with a curved edge, navy heel tab
        _, vv, _ = shoe.local(v)
        cap = smoothstep(-0.006, 0.006, u - shoe.toe_cap_line(vv, z))
        col = mix(col, PAL["white"], cap)
        tab = smoothstep(0.02, -0.02, u + 0.2) * smoothstep(0.3, 0.36, z) * smoothstep(0.1, 0.06, np.abs(vv))
        col = mix(col, PAL["shoe_dark"], tab)

        collar = smoothstep(0.03, 0.0, shoe._collar(np.stack(shoe.local(v), axis=-1)))
        col = mix(col, PAL["shoe_dark"], collar)
        blend(attrs, surface(count, 0.7, sheen=0.4), collar)

        sole = smoothstep(0.012, 0.0, shoe.sole(v))
        zz = z - shoe.toe_spring(u)
        outsole = smoothstep(0.075, 0.065, zz)
        sole_col = mix(PAL["white"], PAL["outsole"], outsole)
        stripe = smoothstep(0.012, 0.004, np.abs(zz - 0.14))
        sole_col = mix(sole_col, PAL["shoe"], stripe * (1 - outsole))
        col = mix(col, sole_col, sole)
        blend(attrs, surface(count, 0.55), sole)
        blend(attrs, surface(count, 0.8), sole * outsole)

        lace = smoothstep(0.01, 0.0, shoe.lace_fn(v))
        col = mix(col, PAL["white"], lace)
        blend(attrs, surface(count, 0.75, sheen=0.5), lace)
        return col, attrs

    return fn


def with_occlusion(paint, fn, strength=0.9, floor=0.45):
    """Darken creases a little, like a painted collectible (and for flat in-game lighting)."""

    def wrapped(v, n):
        col, attrs = paint(v, n)
        ao = sdf.occlusion(fn, v, n, strength=strength)
        return col * (floor + (1 - floor) * ao)[:, None], attrs

    return wrapped


PARTS = [
    {"name": "Body", "fn": g.body, "box": g.BODY_BOX, "step": 0.018, "paint": with_occlusion(paint_body, g.body)},
    {"name": "Teeth", "fn": g.teeth, "box": g.TEETH_BOX, "step": 0.006, "paint": paint_teeth},
    *[
        {"name": f"Sock{i}", "fn": g.SOCK_FNS[i], "box": g.sock_box(i), "step": 0.01, "paint": paint_sock(i)}
        for i in range(3)
    ],
    *[
        {"name": f"Shoe{i}", "fn": g.SHOES[i], "box": g.SHOES[i].box(), "step": 0.01, "paint": with_occlusion(paint_shoe(i), g.SHOES[i])}
        for i in range(3)
    ],
]

EYES = [{"center": e["center"], "gaze": e["gaze"], "radius": g.EYE_RADIUS} for e in g.EYES]
EYE_LOOK = {"iris": "#6b4424", "iris_edge": "#1a0e06", "pupil_size": 0.5, "iris_size": 0.8}
