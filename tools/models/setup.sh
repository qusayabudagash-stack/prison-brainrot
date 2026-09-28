#!/usr/bin/env bash
# Creates a Python 3.11 virtualenv with Blender as a Python module (bpy) plus the meshing libraries.
# Usage: tools/models/setup.sh [venv-dir]   (default: tools/models/.venv)
set -euo pipefail

VENV="${1:-$(dirname "$0")/.venv}"
PYTHON="${PYTHON:-python3.11}"

if ! command -v "$PYTHON" >/dev/null; then
	echo "Blender 4.5's bpy wheels need Python 3.11; set PYTHON=/path/to/python3.11" >&2
	exit 1
fi

"$PYTHON" -m venv "$VENV"
"$VENV/bin/pip" install --upgrade pip
"$VENV/bin/pip" install "bpy==4.5.*" "numpy<2" scipy scikit-image
echo "Ready: $VENV/bin/python tools/models/build.py tralalero_tralala --quality preview"
