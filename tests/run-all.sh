#!/usr/bin/env bash
# Builds the place and runs every test against it. Needs rojo and lune (`rokit install`).
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
rojo build default.project.json -o build/test.rbxl
for test in shared server client studio; do
	echo
	echo "######## $test"
	lune run "tests/$test.test.luau" build/test.rbxl
done
echo
echo "All tests passed."
