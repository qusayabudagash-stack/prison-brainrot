"""Tralalero Tralala's paint and surface properties, computed per vertex from the geometry fields.

Toy look: a few large, bold color regions with crisp edges, simple plastic materials, a subtle
top-to-side gradient and soft baked creases. Kept apart from the geometry so recoloring does not
invalidate the mesh cache.
"""

from __future__ import annotations

import numpy as np

import sdf
import tralalero_tralala as g
from scene import mix, srgb
from sdf import smoothstep

PAL = {
    "blue": srgb("#2f8bff"),
    "blue_top": srgb("#1d62e0"),
    "belly": srgb("#f7f4ee"),
    "brow": srgb("#1a2350"),
    "mouth": srgb("#5a1024"),
    "gum": srgb("#e0506c"),
    "gill": srgb("#1a47a8"),
    "skin": srgb("#f5b88c"),
    "white": srgb("#fbfaf6"),
    "sock_band": srgb("#2f8bff"),
    "sock_band2": srgb("#ff4d5a"),
    "shoe": srgb("#2f7dff"),
    "shoe_dark": srgb("#18307a"),
    "outsole": srgb("#2e2f38"),
    "tooth": srgb("#ffffff"),
    "tongue": srgb("#ff6f8e"),
}


def surface(n, rough, coat=0.0, sheen=0.0, studs=0.0):
    """Per-vertex surface properties; `studs` is how strongly the raised stud surface shows."""
    ones = np.ones(n)
    return {
        "Roughness": ones * rough,
        "CoatWeight": ones * coat,
        "SubsurfaceWeight": ones * 0.0,
        "SheenWeight": ones * sheen,
        "Studs": ones * studs,
    }


def blend(attrs, other, t):
    for key in attrs:
        attrs[key] = attrs[key] * (1 - t) + other[key] * t


def crisp(edge, x, width=0.012):
    """1 below `edge`, 0 above, with a narrow anti-aliased band."""
    return smoothstep(edge + width, edge - width, x)


def paint_body(v, n):
    count = len(v)
    y, z = v[:, 1], v[:, 2]
    centre, half = g.spine(y)
    t = (z - centre) / np.maximum(half, 0.2)

    # Blue back with a subtle darker top, a clean white belly
    col = mix(PAL["blue"], PAL["blue_top"], smoothstep(0.1, 1.0, t) * 0.55)
    belly = crisp(-0.5, t, 0.03)
    # on the head the white starts right at the grin, so the lower jaw is white
    rel = v - g.MOUTH_CENTER
    yaw = np.degrees(np.arctan2(rel[:, 0], -rel[:, 1])) / 60.0
    mouth_z = np.interp(np.clip(yaw, -1, 1), g.MOUTH_S, g.MOUTH_P[:, 2])
    corner = np.clip(np.abs(yaw) - 1.0, 0, None)
    jaw = crisp(mouth_z - corner * 0.8, z, 0.02)
    head = smoothstep(-1.2, -1.7, y)
    belly = belly * (1 - head) + jaw * head
    # fins stay blue all over
    fin = np.minimum.reduce([f(v) for f in g._pects] + [g._tail(v), g._dorsal(v)])
    on_fin = smoothstep(0.06, 0.0, fin) * smoothstep(0.0, 0.12, g.BODY(v))
    belly = belly * (1 - on_fin)
    col = mix(col, PAL["belly"], belly)
    attrs = surface(count, 0.34, coat=0.05, studs=1.0)

    brow = smoothstep(0.04, 0.0, g._brows(v))
    col = mix(col, PAL["brow"], brow)
    blend(attrs, surface(count, 0.45, studs=0.6), brow)
    gill = smoothstep(0.03, 0.0, g._gills(v))
    col = mix(col, PAL["gill"], gill)
    blend(attrs, surface(count, 0.45), gill)

    mouth = smoothstep(0.035, 0.005, g._mouth(v))
    depth = smoothstep(0.02, 0.1, -g.BODY(v))
    col = mix(col, mix(PAL["gum"], PAL["mouth"], depth), mouth)
    blend(attrs, surface(count, 0.35, coat=0.1), mouth)

    skin = smoothstep(0.03, -0.03, g._legs(v) - g.shark(v))
    col = mix(col, PAL["skin"], skin)
    blend(attrs, surface(count, 0.5, studs=0.7), skin)
    return col, attrs


def paint_flat(color, rough, coat=0.0):
    def fn(v, n):
        return np.tile(PAL[color], (len(v), 1)), surface(len(v), rough, coat=coat)

    return fn


def paint_sock(v, n):
    z = v[:, 2]
    col = np.tile(PAL["white"], (len(v), 1))
    col = mix(col, PAL["sock_band"], crisp(0.045, np.abs(z - (g.SOCK_TOP - 0.24)), 0.008))
    return col, surface(len(v), 0.8, sheen=0.3)


def paint_shoe(i):
    shoe = g.SHOES[i]

    def fn(v, n):
        count = len(v)
        u, vv, z = shoe.local(v)
        col = np.tile(PAL["shoe"], (count, 1))
        attrs = surface(count, 0.36, coat=0.05, studs=1.0)

        # white toe cap, navy heel tab and padded collar
        col = mix(col, PAL["white"], smoothstep(-0.01, 0.01, u - shoe.toe_cap_line(vv, z)))
        tab = smoothstep(0.03, -0.03, u + 0.18) * smoothstep(0.34, 0.4, z) * smoothstep(0.13, 0.09, np.abs(vv))
        col = mix(col, PAL["shoe_dark"], tab)
        collar = smoothstep(0.03, 0.0, shoe._collar(np.stack([u, vv, z], axis=-1)))
        col = mix(col, PAL["shoe_dark"], collar)

        # chunky white sole with a dark outsole and a blue stripe
        sole = smoothstep(0.015, 0.0, shoe.sole(v))
        zz = z - shoe.toe_spring(u)
        outsole = smoothstep(0.085, 0.075, zz)
        sole_col = mix(PAL["white"], PAL["outsole"], outsole)
        sole_col = mix(sole_col, PAL["shoe"], smoothstep(0.022, 0.014, np.abs(zz - 0.165)) * (1 - outsole))
        col = mix(col, sole_col, sole)
        blend(attrs, surface(count, 0.5, studs=0.3), sole)

        lace = smoothstep(0.012, 0.0, shoe.lace_fn(v))
        col = mix(col, PAL["white"], lace)
        blend(attrs, surface(count, 0.7, sheen=0.3), lace)
        return col, attrs

    return fn


def with_occlusion(paint, fn, strength=0.8, floor=0.6):
    """Soft baked creases, like a painted toy (and for Roblox's flatter lighting)."""

    def wrapped(v, n):
        col, attrs = paint(v, n)
        ao = sdf.occlusion(fn, v, n, delta=0.08, strength=strength)
        return col * (floor + (1 - floor) * ao)[:, None], attrs

    return wrapped


PARTS = [
    {"name": "Body", "fn": g.body, "box": g.BODY_BOX, "step": 0.02, "paint": with_occlusion(paint_body, g.body), "budget": 12000},
    {"name": "Teeth", "fn": g.teeth, "box": g.TEETH_BOX, "step": 0.008, "paint": paint_flat("tooth", 0.3, coat=0.3), "budget": 1800, "sharp": 40},
    {"name": "Tongue", "fn": g.tongue, "box": g.TONGUE_BOX, "step": 0.01, "paint": paint_flat("tongue", 0.4, coat=0.2), "budget": 300},
    *[{"name": f"Sock{i}", "fn": g.SOCK_FNS[i], "box": g.sock_box(i), "step": 0.012, "paint": paint_sock, "budget": 500} for i in range(3)],
    *[
        {"name": f"Shoe{i}", "fn": g.SHOES[i], "box": g.SHOES[i].box(), "step": 0.012, "paint": with_occlusion(paint_shoe(i), g.SHOES[i]), "budget": 2400}
        for i in range(3)
    ],
]

EYES = [{"center": e["center"], "gaze": e["gaze"], "radius": g.EYE_RADIUS} for e in g.EYES]
EYE_LOOK = {"iris": None, "pupil_size": 0.62, "highlight": True}
