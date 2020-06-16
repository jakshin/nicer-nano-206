#!/bin/bash -e
# Tests nano-smart-indent.sh's handling of conflicting indentations.

# FIXME

script_dir="$(dirname -- "$0")"
cd -- "$script_dir"

export NANO_SMART_INDENT_TESTING_CONFLICTS=true

# If tabstospaces is passed, EditorConfig and existing indentation don't set indent_style

# If tabsize is passed, EditorConfig and existing indentation don't set indent_size

# If files have different indent styles, prompt for confirmation

# If files have identical indent styles, silently continue

