#!/bin/bash
#
# A wrapper script for nano; it passes its arguments through to the real nano, and also
# tries to detect whether the file(s) being opened should use spaces or tabs for indentation,
# and adjust nano's behavior accordingly by passing it `--tabstospaces` and/or `--tabsize`,
# so nano's indentation behavior will "automatically" match the file being edited.
#
# If nano is being opened with a new/non-existent file, or multiple files with different
# indentation styles from each other, this script doesn't pass any extra options to nano
# (although it still passes through any options received on its own command line, of course).
#
# Copyright (c) 2020 Jason Jackson. MIT License.
#



# FIXME explain all of the below in the README

# allow passing --tabs to suppress indentation detection and use tabs;
# if you also pass --tabstospaces, it wins, even if it was passed first

# would be nice to be able to default to spaces for indentation, when detection doesn't work;
# if $NANO_SMART_INDENT_PREFER_SPACES is true, pass --tabstospaces to nano (without --tabsize),
# in the case where detect-indent returns an empty string


# FIXME if `editorconfig` CLI is installed, use it for each file, with conflict detection, 
# unless an environment variable suppresses it: NANO_SMART_INDENT_NO_EDITORCONFIG=true
# https://github.com/editorconfig/editorconfig/wiki/EditorConfig-Properties:
# use indent_style, indent_size, tab_width
# could also use insert_final_newline, max_line_length, but maybe save those for nano-editorconfig?
# (If insert_final_newline = false, and your a ends in a newline, VS Code's EditorConfig plugin doesn't remove it)



# Parse the command line like nano v2.0.6 will
# (Just enough to understand which file(s) will be edited, and a few relevant options)
declare -a files
maybe_file=""        # Arguments that start with "+" might or might not be file names
options_ended=false  # Options can be interspersed with file names, but "--" ends all options
tabsize_value_needed=false
tabsize=""
tabstospaces=""
will_edit=true

for arg; do
	# Remove options which aren't real nano options from the command line we'll pass to nano
	# https://unix.stackexchange.com/questions/258512/how-to-remove-a-positional-parameter-from
	shift
	[[ $arg == "--tabs" ]] || set -- "$@" "$arg"

	# Process the argument
	if [[ $tabsize_value_needed == true ]]; then
		tabsize_value_needed=false
		tabsize="$arg"
		continue

	elif [[ $arg == "--" && $options_ended == false ]]; then
		# This can come between a '+n,n' argument and a file name, with no effect
		options_ended=true

	elif [[ ($arg == "--help" || $arg == "--version") && $options_ended == false ]]; then
		will_edit=false
		break

	elif [[ $arg == "--tabsize"* && $options_ended == false ]]; then
		# If an equal sign is present, the rest of the arg is tab size, else the next arg is
		[[ $arg == "--tabsize="* ]] && tabsize="${arg#--tabsize=}" || tabsize_value_needed=true

	elif [[ $arg == "--tabstospaces" && $options_ended == false ]]; then
		tabstospaces=true

	elif [[ $arg == "--tabs" && $options_ended == false ]]; then
		# This isn't a real nano option; it means the inverse of '--tabstospaces',
		# i.e. requests to use tabs for indentation regardless of the file content
		[[ $tabstospaces == true ]] || tabstospaces=false

	elif [[ $arg == -* && $options_ended == false ]]; then
		if [[ $arg == *T* ]]; then
			# If characters follow a T option, the rest of the arg is tab size, else the next arg is
			[[ $arg == *T ]] && tabsize_value_needed=true || tabsize="${arg//*T/}"
			arg="${arg//T*/}"
		fi

		# '?', 'h' and 'V' can be bundled with other short options
		if [[ $arg == *"?"* || $arg == *h* || $arg == *V* ]]; then
			will_edit=false
			break
		fi

	elif [[ $arg == +* ]]; then
		# FIXME what happens if the whole argument is just "+"? or "+foo", without a number?
		if [[ -n $maybe_file ]]; then
			maybe_file=""
			files+=("$arg")
		else
			maybe_file="$arg"
		fi

	else
		# This is either an ordinary argument,
		# or one that looks like an option but "--" was previously passed
		maybe_file=""
		files+=("$arg")  # Could be empty -- that's fine, it's a valid file name to nano
	fi
done

if [[ -n $maybe_file ]]; then
	files+=("$maybe_file")
fi

# FIXME test: if tabstospaces is true and we do detection to get the tab size,
# what should we do if we detect tabs? just don't send --tabsize=tab to nano

# Detect indentation, if needed
if [[ $will_edit == true && ${#files[@]} != 0 && ($tabstospaces == "" || $tabsize == "") ]]; then
	if [[ $NANO_SMART_INDENT_NO_EDITORCONFIG != true ]] && type -t editorconfig > /dev/null; then
		use_editorconfig=true
	fi

	script_dir="$(dirname -- "$0")"
	source "$script_dir/detect-indent.sh"  # FIXME do this conditionally, below

	indent_style=""
	indent_size=""

	for file in "${files[@]}"; do
		_indent_style="" _indent_size=""  # Assigned in use-editorconfig/detect-indent

		if [[ $use_editorconfig == true && -n $file ]]; then
			: # FIXME call use-editorconfig
		fi

		detect-indent "$file"  # Sets $_indent_style/$_indent_size

		if [[ -n $_indent_style ]]; then
			if [[ -n $indent_style && "$indent_style" != "$_indent_style" ]]; then
				# Conflicting indentation style detected across multiple files -- pull the ripcord
				indent_style=""
				break  # FIXME set a flag value like we we with indent_size
			else
				indent_style="$_indent_style"
			fi
		fi

		if [[ -n $_indent_size && $indent_size != "-" ]]; then
			if [[ -n $indent_size && "$indent_size" != "$_indent_size" ]]; then
				# Conflicting indent size detected across multiple files; set a flag value
				# and give up on auto-configuring indent size, but keep trying for indent style
				indent_size="-"
			else
				indent_size="$_indent_size"
			fi
		fi
	done
fi

if [[ $indent_size == "-" ]]; then
	indent_size=""
fi

# Run nano
[[ $NANO_SMART_INDENT_TESTING == true ]] && cmd="echo" || cmd="exec"
cmd="echo" # FIXME testing

if [[ $tabstospaces == "" &&
	($indent_style == "space" || ($indent_style == "" && $NANO_SMART_INDENT_PREFER_SPACES == true)) ]]
then
	nano_args="--tabstospaces"
fi

if [[ $tabsize == "" && $indent_size != "" ]]; then
	[[ -z $nano_args ]] || nano_args+=" "
	nano_args+="--tabsize=$indent_size"
fi

$cmd /usr/bin/nano $nano_args "$@"
