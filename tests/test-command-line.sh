#!/bin/bash -e
# Tests the nano206++.sh script's command-line handling.

script_dir="$(dirname -- "$0")"
cd -- "$script_dir"

export NANO_SMART_INDENT_TESTING_CMD_LINE=true
errors=0
output=""  # Set in run-test, read in check-output

dim_color="\033[38;5;240m"
error_color="\033[1;31m"
ok_color="\033[32m"
no_color="\033[0m"

function run-test() {
	[[ $first_test == false ]] && echo || first_test=false

	echo -n "Incoming arguments: "
	[[ $# == 0 ]] && echo -e "${dim_color}none${no_color}" || echo "$@"

	output="$("$script_dir/../scripts/nano206++.sh" "$@" 2>&1)"
}

function check-output() {
	declare -a expected=("$1" "$2" "$3" "$4")  # Files, will edit, $tabstospaces, $tabsize

	local lines
	IFS=$'\n' lines=($output)  # Will get globbed, but shouldn't contain any glob characters anyway

	local line_num line
	for (( line_num=0; line_num < ${#lines[@]}; line_num++ )); do
		line="${lines[$line_num]}"

		if (( line_num >= ${#expected[@]} )); then
			echo "  $line"
		elif [[ -z ${expected[$line_num]} && $line != *" -" ]]; then  # Ugh, yuck
			echo -e "  ${error_color}${line}${no_color}"
			(( errors++ ))
		elif [[ $line == *"${expected[$line_num]}" ]]; then
			echo -e "  ${ok_color}${line}${no_color}"
		else
			echo -e "  ${error_color}${line}${no_color}"
			(( errors++ ))
		fi
	done
}

# We shouldn't pass --tabs to nano, unless it's a file name
run-test -A --tabs -B foo.txt
check-output "foo.txt" true false -

if [[ $output == *"--tabs"* ]]; then
	echo -e "  ${error_color}^ oops, passed --tabs option to nano${no_color}"
	(( errors++ ))
fi

run-test -- --tabs
check-output "--tabs" true - -

if [[ $output != *"--tabs"* ]]; then
	echo -e "  ${error_color}^ oops, didn't pass --tabs file name to nano${no_color}"
	(( errors++ ))
fi

# Tab size can be specified in a single argument
run-test -T3
check-output "" true - 3

run-test --tabsize=5 "foo.txt"
check-output "foo.txt" true - 5

run-test "foo.txt" --tabsi=6
check-output "foo.txt" true - 6

# These should all result in us using the second argument as $tabsize 
run-test -T 2
check-output "" true - 2

run-test -T -- 2 foo.txt      # Nano takes the "--" as the tab size
check-output "2 foo.txt" true - --

run-test --tabsize 4 foo.txt
check-output "foo.txt" true - 4

run-test --tabsize foo.txt    # Whoops, left tabsize's value out
check-output "" true - "foo.txt"

run-test -T --help
check-output "" true - "--help"

# We should treat the 3rd argument as a file
run-test -A -- -B
check-output "-B" true - -

run-test -A -- --
check-output "--" true - -

# Nano won't actually enter edit mode in any of these cases
run-test -hT 2 foo.txt
check-output "foo.txt" false - 2

run-test --tabsize=4 --help
check-output "" false - 4

run-test --he
check-output "" false - -

run-test -AV foo.txt
check-output "foo.txt" false - -

run-test foo.txt --version bar.txt
check-output "foo.txt bar.txt" false - -

run-test --ver
check-output "" false - -

run-test "-?"
check-output "" false - -

# Tabs/spaces options
run-test "foo.txt" --tabstospaces
check-output "foo.txt" true true -

run-test "foo.txt" --tabst
check-output "foo.txt" true true -

run-test "foo.txt" --tabstosp
check-output "foo.txt" true true -

run-test "foo.txt" --tabstox  # Nano will toss an "unrecognized option" error
check-output "foo.txt" true - -

run-test -AET 2 "foo.txt"
check-output "foo.txt" true true 2

run-test --tabs
check-output "" true false -

run-test --tabs --tabstospaces "foo.txt" --tabs "bar.txt" --tabs
check-output "foo.txt bar.txt" true true -

# Arguments that begin with "+" might or might not be file names,
# depending the arguments that follow them
run-test +2,2
check-output "+2,2" true - -

run-test +2,2 "foo.txt"
check-output "foo.txt" true - -

run-test -- +2,2 "foo.txt"
check-output "foo.txt" true - -

run-test -T 2 +2,2 -E "foo.txt"  # Options can come between a +n,n and its file
check-output "foo.txt" true true 2

run-test +2,2 -T 2 "foo.txt"
check-output "foo.txt" true - 2

run-test +2,2 -- "--help"
check-output "--help" true - -

# The argument "-" is a file name, not an option
run-test -
check-output "-" true - -

# Passing an empty file name to nano is valid, and results in an unnamed new buffer
run-test "foo.txt" "" "bar.txt"
check-output "foo.txt  bar.txt" true - -

# Use EditorConfig and indentation detection when we need to, but only then
function use-editorconfig() { files+=("use-editorconfig"); }
function detect-indent() { files+=("detect-indent"); }
export -f use-editorconfig detect-indent

run-test "dummy.txt"
check-output "dummy.txt use-editorconfig detect-indent" true - -

run-test
check-output "" true - -

run-test "dummy.txt" --tabstospaces --tabsize=2
check-output "dummy.txt" true true 2

function use-editorconfig() { files+=("use-editorconfig"); _indent_style=tab; _indent_size=4; }

run-test "dummy.txt"
check-output "dummy.txt use-editorconfig" true - -

export NANO_SMART_INDENT_NO_EDITORCONFIG=true

run-test "dummy.txt"
check-output "dummy.txt detect-indent" true - -

unset -f use-editorconfig detect-indent
unset NANO_SMART_INDENT_NO_EDITORCONFIG

# Use $NANO_SMART_INDENT_PREFER_SPACES
export NANO_SMART_INDENT_PREFER_SPACES=true

run-test "foo.txt"
check-output "foo.txt" true - -

if [[ $output != *"--tabstospaces"* ]]; then
	echo -e "  ${error_color}^ oops, didn't pass --tabstospaces option to nano${no_color}"
	(( errors++ ))
fi

run-test --tabs "foo.txt"
check-output "foo.txt" true false -

if [[ $output == *"--tabstospaces"* ]]; then
	echo -e "  ${error_color}^ oops, passed --tabstospaces option to nano${no_color}"
	(( errors++ ))
fi

tmp_file="$(mktemp)"
echo -e "\tline" >> "$tmp_file"

run-test "$tmp_file"
check-output "$tmp_file" true - -
rm -f "$tmp_file"

if [[ $output == *"--tabstospaces"* ]]; then
	echo -e "  ${error_color}^ oops, passed --tabstospaces option to nano${no_color}"
	(( errors++ ))
fi

unset NANO_SMART_INDENT_PREFER_SPACES

# Summarize
if (( errors > 1 )); then
	echo -e "\n😖\033[1;31m $errors errors"
elif [[ $errors == 1 ]]; then
	echo -e "\n😞\033[1;31m 1 error"
else
	echo -e "\n👌"
fi
