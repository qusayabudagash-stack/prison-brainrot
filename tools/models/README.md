# Brainrot model pipeline (Blender)

Dev tooling, not part of the game build. Characters are sculpted in code as signed distance
fields (`sdf.py`): bodies, fins, faces and limbs blend into one seamless surface, which marching
cubes turns into a mesh. Blender (as a Python module) paints, lights and renders them with Cycles.

```
tools/models/setup.sh                      # venv with bpy 4.5, numpy, scipy, scikit-image
.venv/bin/python tools/models/build.py tralalero_tralala --quality preview --views threequarter
.venv/bin/python tools/models/build.py tralalero_tralala --quality final \
    --views threequarter,front,side,thumbnail,scale
```

- `sdf.py`: distance-field shapes (`Loft` bodies with round or rounded-box sections, `Blade` fins,
  capsules, ellipsoids), smooth union/carve, narrow-band meshing, surface projection and baked
  occlusion.
- `scene.py`: Blender helpers: meshes from arrays with per-vertex paint, materials, studio, camera.
- `build.py`: meshes a character's parts (cached in `.cache/`), paints them and renders the views
  (`threequarter`, `front`, `side`, `back`, `thumbnail`, `face`, `shoes`, `scale` next to a
  5-stud blocky avatar, `gameplay` from a Roblox camera distance on a grass baseplate, and
  `silhouette` / `silhouette_side` as flat black shapes). `--game` renders the in-game meshes,
  each part cut to its triangle budget; `--skip Teeth,Tongue` leaves parts out while debugging.
- `characters/<name>.py`: the character's geometry; `characters/<name>_look.py`: its paint and
  surface properties (kept apart so recoloring does not re-sculpt).

Coordinates: x right, y back (characters face -y), z up, 1 unit = 1 Roblox stud.
