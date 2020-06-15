#!/bin/bash
#
# This is a wrapper script for nano, which passes its arguments to nano, after first trying to
# figure out the best indentation settings for the file(s) being edited, and passing additional
# options to nano to adjust its indentation behavior as needed. The most convenient way to use
# it is through an alias: alias nano=/path/to/nano-smart-indent.sh
#
# It first tries to use EditorConfig settings, as reported by the editorconfig CLI. This works
# on both existing and new files, since finding a relevant .editorconfig file only depends on
# the edited file's path. If the editorconfig CLI isn't installed, this step is skipped; if it
# is installed but you don't want this script to use it, put this in your .bashrc and/or .zshrc:
# export NANO_SMART_INDENT_NO_EDITORCONFIG=true
#
# If EditorConfig settings aren't found (or aren't used), the script next tries to read up to
# 20 KB from the file, and detect its indentation style. This, of course, only works on files
# that already exist.
#
# For all of this to work, neither /etc/nanorc nor ~/.nanorc can contain "set tabstospaces";
# that's because nano doesn't provide a command-line option which tells it to use tabs for
# indentation, so if you've told it to use spaces for indentation in one of its config files,
# this script has no way to change that setting. And _that_, in turn, means that if this script
# can't detect a file's indentation style, nano's default setting of using tabs for indentation
# will come into play. If you're more a spaces-for-indentation kind of person, put this into
# your .bashrc and/or .zshrc to tell this script to default to having nano indent with spaces
# when it can't figure out what else to do: export NANO_SMART_INDENT_PREFER_SPACES=true
#
# You can always pass --tabstospaces (or -E) if you want to indent a given file with spaces,
# and this script will dutifully pass that setting along to nano, regardless of what EditorConfig
# thinks or the contents already in the file. You can also pass --tabs, which isn't an actual
# nano option, but which this script takes as the opposite of --tabstospaces, and which will
# make it _not_ tell nano to indent with spaces, regardless of EditorConfig's opinion, etc.
# If you pass both --tabstospaces and --tabs, --tabstospaces always wins, regardless of order.
#
# The --tabsize (or -T) option is also passed through, setting the tab display width when
# indenting with tabs, or the number of spaces to use when indenting with spaces. If you don't
# pass it, either the relevant EditorConfig setting or the existing indentation width in the file
# will be used, or - if neither of those are applicable/available - the `tabsize` setting from
# nano's config files, or its compiled-in default of 8.
#
# Copyright (c) 2020 Jason Jackson. MIT License.
#

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

# Detect indentation, if needed
if [[ $will_edit == true && ${#files[@]} != 0 && (-z $tabstospaces || -z $tabsize) ]]; then
	if [[ $NANO_SMART_INDENT_NO_EDITORCONFIG != true ]] && type -t editorconfig > /dev/null; then
		use_editorconfig=true
	fi

	indent_conflict=false
	indent_style=""
	indent_size=""

	for file in "${files[@]}"; do
		_indent_style="" _indent_size=""  # Assigned in use-editorconfig/detect-indent

		if [[ -n $file ]]; then
			[[ $use_editorconfig == true ]] && use-editorconfig "$file"  # Sets $_indent_style/$_indent_size

			if [[ (-z $tabstospaces && -z $_indent_style) || (-z $tabsize && -z $_indent_size) ]]; then
				type -d detect-indent > /dev/null || source "$(dirname -- "$0")/detect-indent.sh"
				detect-indent "$file"  # Sets $_indent_style/$_indent_size
			fi
		fi

		# if tabstospaces isn't set, and we detected an indent style:
		# 	if we don't have an indent style yet, adopt the one we detected
		# 	else if the detected style doesn't match the previous one, conflict & break
		if [[ -z $tabstospaces && -n $_indent_style ]]; then
			if [[ -z $indent_style ]]; then
				indent_style="$_indent_style"
			elif [[ "$indent_style" != "$_indent_style" ]]; then
				indent_conflict=true
				break
			fi
		fi

		# if tabsize isn't set, and we detected an indent size:
		# 	if we don't have an indent size yet, adopt the one we detected
		# 	else if the detected size doesn't match the previous one:
		# 		if indent style is space, conflict & break
		if [[ -z $tabsize && -n $_indent_size ]]; then
			if [[ -z $indent_size ]]; then
				indent_size="$_indent_size"
			elif [[ "$indent_size" != "$_indent_size" && "$indent_style" == "space" ]]; then
				indent_conflict=true
				break
			fi
		fi
	done
fi

# FIXME Prompt if we've detected conflicting indentation styles

# Run nano
[[ $NANO_SMART_INDENT_TESTING == true ]] && cmd="echo" || cmd="exec"
cmd="echo" # FIXME testing

if [[ -z $tabstospaces &&
	($indent_style == "space" || ($indent_style == "" && $NANO_SMART_INDENT_PREFER_SPACES == true)) ]]
then
	nano_args="--tabstospaces"
fi

if [[ -z $tabsize && -n $indent_size ]]; then
	[[ -z $nano_args ]] || nano_args+=" "
	nano_args+="--tabsize=$indent_size"
fi

$cmd /usr/bin/nano $nano_args "$@"