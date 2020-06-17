#!/bin/bash -e
# Tests the detect-indent function.

script_dir="$(dirname -- "$0")"
cd -- "$script_dir"
source "../scripts/detect-indent.sh"

function run-test() {
  local fixture_file="$1" expected_style="$2" expected_size="$3"

	_indent_style="" _indent_size=""
	detect-indent "$fixture_file"
	[[ -n $_indent_style ]] || _indent_style="-"
	[[ -z $_indent_size ]] || _indent_size="($_indent_size)"

  local color
  [[ "$_indent_style" == "$expected_style" ]] && color="32m" || color="1;31m"
  _indent_style="\033[${color}${_indent_style}\033[0m"
  [[ "$_indent_size" == "$expected_size" ]] && color="32m" || color="1;31m"
  _indent_size="\033[${color}${_indent_size}\033[0m"

	echo -e "$(basename "$fixture_file"):"$'\t'"$_indent_style $_indent_size"
}

for fixture_file in not-there.txt fixtures/*; do
	digits=${fixture_file//[^0-9]/}
	if [[ -n $digits && $fixture_file != *"UTF"* ]]; then
		expected_style="space"
		expected_size="($digits)"
	elif [[ $fixture_file == *"tab"* ]]; then
		expected_style="tab"
		expected_size=""
	else
		expected_style="-"
		expected_size=""
	fi

	run-test "$fixture_file" "$expected_style" "$expected_size"
done
