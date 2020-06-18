#!/bin/bash -e
# Tests the use-editorconfig function.

script_dir="$(dirname -- "$0")"
cd -- "$script_dir"
source "../scripts/functions/use-editorconfig.sh"

function create-editorconfig-file() {
	echo "root=true" > .editorconfig
	echo "[*]" >> .editorconfig

	local line
	for line in "$@"; do
		echo "$line" >> .editorconfig
	done
}

function run-test() {
	local test_desc="$1" expected_style="$2" expected_size="$3"

	[[ $first_test == false ]] && echo || first_test=false
	echo -e "$test_desc"

	use-editorconfig "a file.txt"
	[[ -n $_indent_style ]] || _indent_style="-"
	[[ -n $_indent_size ]] || _indent_size="-"

	local color
	[[ "$_indent_style" == "$expected_style" ]] && color="32m" || color="1;31m"
	_indent_style="\033[${color}${_indent_style}\033[0m"
	[[ "$_indent_size" == "$expected_size" ]] && color="32m" || color="1;31m"
	_indent_size="\033[${color}${_indent_size}\033[0m"

	echo -e "  indent style: $_indent_style"
	echo -e "  indent size:  $_indent_size"
}

function cleanup() {
	if [[ $all_tests_ran != true ]]; then
		echo -e "\n\033[1;31m--- Aborted, one or more tests didn't run ---"
	fi

	if [[ -n $tmp_dir ]]; then
		cd
		rm -rf "$tmp_dir"
	fi
}

trap cleanup EXIT

tmp_dir="$(mktemp -d)"
mkdir "$tmp_dir/a directory"
cd "$tmp_dir/a directory"
touch "a file.txt"

run-test ".editorconfig doesn't exist" - -
run-test ".editorconfig doesn't exist (/dev/null)" - -

create-editorconfig-file "indent_style=space"
run-test "indent_style=space alone" space -

create-editorconfig-file "indent_style=space" "indent_size=blah"
run-test "indent_style=space, indent_size isn't valid" space -

create-editorconfig-file "indent_style=space" "indent_size=2"
run-test "indent_style=space, indent_size is valid" space 2

create-editorconfig-file "indent_style=tab"
run-test "indent_style=tab alone" tab -

create-editorconfig-file "indent_style=tab" "tab_width=blah" "indent_size=blah"
run-test "indent_style=tab, tab_width isn't valid, indent_size isn't valid" tab -

create-editorconfig-file "indent_style=tab" "tab_width=blah" "indent_size=4"
run-test "indent_style=tab, tab_width isn't valid, indent_size is valid" tab 4

create-editorconfig-file "indent_style=tab" "tab_width=4" "indent_size=8"
run-test "indent_style=tab, tab_width is valid, indent_size is valid & different" tab 4

create-editorconfig-file "tab_width=8"
run-test "indent_style isn't present, tab_width is valid" - 8

all_tests_ran=true
