#!/bin/bash -e
# Tests the use-editorconfig function.

script_dir="$(dirname -- "$0")"
cd -- "$script_dir"
source "../scripts/use-editorconfig.sh"

# FIXME write tests

# .editorconfig in same directory
# .editorconfig in parent directory
# no .editorconfig
# path doesn't exist, .editorconfig is present
# path doesn't exist, no .editorconfig
# /dev/null
# path isn't absolute (editorconfig errors)
