#!/bin/bash -e
# Tests the detect-indent function.

script_dir="$(dirname -- "$0")"
cd -- "$script_dir"
source "../scripts/detect-indent.sh"

for fixture_file in not-there.txt fixtures/*; do
	detect-indent "$fixture_file"  # Sets $_indent_style/$_indent_size

	[[ -n $_indent_style ]] || _indent_style="-"
	[[ -z $_indent_size ]] || _indent_size="($_indent_size)"

	echo "$(basename "$fixture_file"):"$'\t'"$_indent_style $_indent_size"
done
