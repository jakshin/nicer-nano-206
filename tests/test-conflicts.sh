#!/bin/bash -e
# Tests nano-smart-indent.sh's handling of conflicting indentations.

script_dir="$(dirname -- "$0")"
cd -- "$script_dir"

export NANO_SMART_INDENT_TESTING_CONFLICTS=true
errors=0
output=""	# Set in run-test, read in check-output

dim_color="\033[38;5;240m"
error_color="\033[1;31m"
ok_color="\033[32m"
no_color="\033[0m"

function run-test() {
	[[ $first_test == false ]] && echo || first_test=false

	echo -n "Incoming arguments: "
	[[ $# == 0 ]] && echo -e "${dim_color}none${no_color}" || echo "$@"

	output="$("$script_dir/../scripts/nano-smart-indent.sh" "$@" 2>&1)"
}

function check-output() {
	local expect_conflict="$1"
	local expect_tabstospaces="$2"
	local expect_tabsize="$3"
	local expect_in_args="$4"  # Optional, expected substring of the arguments passed to nano

	if echo "$output" | grep -Fiq "conflicting"; then
		local conflict=true
	else
		local conflict=false
	fi

	local result
	if [[ $conflict != "$expect_conflict" ]]; then
		[[ $expect_conflict == true ]] && result="Didn't get expected conflict" || result="Unexpected conflict"
		echo -e "  ${error_color}${result}${no_color}"
		(( errors+=1 ))
	else
		[[ $expect_conflict == true ]] && result="Got expected conflict" || result="No conflict, as expected"
		echo -e "  ${ok_color}${result}${no_color}"
	fi

	local nano_line
	nano_line="$(echo "$output" | grep /usr/bin/nano)"

	local tabstospaces tabsize
	echo "$nano_line" | grep -Fq -- "--tabstospaces" && tabstospaces=true || tabstospaces=false
	echo "$nano_line" | grep -Fq -- "--tabsize" && tabsize=true || tabsize=false

	if [[ $tabstospaces != "$expect_tabstospaces" || $tabsize != "$expect_tabsize" ]]; then
		echo -e "  ${error_color}${nano_line}${no_color}"
		(( errors+=1 ))
	elif [[ -n $expect_in_args ]] && ! (echo "$nano_line" | grep -Fq -- "$expect_in_args"); then
		echo -e "  ${error_color}${nano_line}${no_color}  (missing $expect_in_args)"
		(( errors+=1 ))
	else
		echo -e "  ${ok_color}${nano_line}${no_color}"
	fi
}

# If files have identical indent styles, silently continue
run-test "fixtures/tab-mixed.js" "fixtures/tab-only.js"
check-output false false false

# If space-indented files have identical indent sizes, silently continue
run-test "fixtures/sp4-mixed.js" "fixtures/sp4-only.js"
check-output false true true

# If one file has detectable indentation, and another doesn't, silently continue
run-test "fixtures/tab-mixed.js" "fixtures/empty.txt"
check-output false false false

run-test "fixtures/zero.txt" "fixtures/sp4-mixed.js"
check-output false true true

# Test interactions between indentation options and conflicting detected indentations
# First let's mock use-editorconfig

function use-editorconfig() {
	local file_path="$1"
	export _indent_style="" _indent_size=""

	if [[ $file_path == *"tab"* || $file_path == *"space"* ]]; then
		[[ $file_path == *"tab"* ]] && _indent_style=tab || _indent_style=space
		[[ $file_path == *2* ]] && _indent_size=2
		[[ $file_path == *4* ]] && _indent_size=4
	fi
}

export -f use-editorconfig

# EditorConfig says tabs for one file, spaces for another, pass no options -> prompt, tabs
# EditorConfig says tabs for one file, spaces for another, pass --tabs -> never checked, tabs
# EditorConfig says tabs for one file, spaces for another, pass --tabstospaces -> never checked, spaces
# EditorConfig says tabs for one file, spaces for another, pass --tabsize=3 -> prompt, tabs

run-test "tabs" "spaces"
check-output true false false

run-test "tabs" "spaces" --tabs
check-output false false false

run-test "tabs" "spaces" --tabstospaces
check-output false true false

run-test "tabs" "spaces" --tabsize=3
check-output true false true "--tabsize=3"

# EditorConfig says spaces/2 for one file, spaces/4 for another, pass no options -> prompt, spaces/2
# EditorConfig says spaces/2 for one file, spaces/4 for another, pass --tabs -> silently continue, use tabs/2
# EditorConfig says spaces/2 for one file, spaces/4 for another, pass --tabstospaces -> prompt, spaces/2
# EditorConfig says spaces/2 for one file, spaces/4 for another, pass --tabsize=3 -> silently continue, use spaces/3

run-test "2-spaces" "4-spaces"
check-output true true true "--tabsize=2"

run-test "2-spaces" "4-spaces" --tabs
check-output false false true "--tabsize=2"

run-test "2-spaces" "4-spaces" --tabstospaces
check-output true true true "--tabsize=2"

run-test "2-spaces" "4-spaces" --tabsize=3
check-output false true true "--tabsize=3"

# EditorConfig says tabs/2 for one file, tabs/4 for another, pass no options -> silently continue, use tabs/2
# EditorConfig says tabs/2 for one file, tabs/4 for another, pass --tabs -> silently continue, use tabs/2
# EditorConfig says tabs/2 for one file, tabs/4 for another, pass --tabstospaces -> prompt, spaces/2
# EditorConfig says tabs/2 for one file, tabs/4 for another, pass --tabsize=3 -> silently continue, use tabs/3

run-test "2-tabs" "4-tabs"
check-output false false true "--tabsize=2"

run-test "2-tabs" "4-tabs" --tabs
check-output false false true "--tabsize=2"

run-test "2-tabs" "4-tabs" --tabstospaces
check-output true true true "--tabsize=2"

run-test "2-tabs" "4-tabs" --tabsize=3
check-output false false true "--tabsize=3"

# Summarize
if (( errors > 1 )); then
	echo -e "\n😖\033[1;31m $errors errors"
elif [[ $errors == 1 ]]; then
	echo -e "\n😞\033[1;31m 1 error"
else
	echo -e "\n👌"
fi
