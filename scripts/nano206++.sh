#!/bin/bash
#
# This is a wrapper script for nano v2.0.6, which passes its arguments through to the real nano,
# after first trying to figure out the best indentation settings for the file(s) being edited,
# and adding more options to nano's command line, if needed, to adjust its indentation behavior.
#
# It first tries to use EditorConfig settings, as reported by the editorconfig CLI. This works
# on both existing and new files, since finding a relevant .editorconfig file only depends on
# the edited file's path. If the editorconfig CLI isn't installed, this step is skipped; if it
# is installed but you don't want this script to use it, put this in your .bashrc and/or .zshrc:
# export NICER_NANO_NO_EDITORCONFIG=true
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
# when it can't figure out what else to do: export NICER_NANO_PREFER_SPACES=true
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
# will be used, or -- if neither of those are applicable/available -- the `tabsize` setting from
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
	[[ $arg == "--tabs" && $options_ended == false ]] || set -- "$@" "$arg"

	# Process the argument
	if [[ $tabsize_value_needed == true ]]; then
		tabsize_value_needed=false
		tabsize="$arg"
		continue
	fi

	if [[ $options_ended == false && $arg == -* && $arg != - ]]; then
		if [[ $arg == "--" ]]; then
			# This can come between a '+n,n' argument and a file name, with no effect
			options_ended=true

		elif [[ "--help" == "$arg"* || "--version" == "$arg"* ]]; then
			will_edit=false  # Nano will error on --h or --v; --he or longer and --ve or longer work

		elif [[ $arg == "--tabsize" || $arg == "--tabsiz" || $arg == "--tabsi" ||
			$arg == "--tabsize="* || $arg == "--tabsiz="* || $arg == "--tabsi="* ]]
		then
			# If an equal sign is present, the rest of the arg is tab size, else the next arg is
			[[ $arg == *=* ]] && tabsize="${arg//*=/}" || tabsize_value_needed=true

		elif [[ "--tabstospaces" == "$arg"* && "$arg" == "--tabst"* ]]; then
			tabstospaces=true

		elif [[ $arg == "--tabs" ]]; then
			# This isn't a real nano option; it means the inverse of '--tabstospaces',
			# i.e. requests to use tabs for indentation regardless of EditorConfig / file content
			[[ $tabstospaces == true ]] || tabstospaces=false

		elif [[ $arg == --* ]]; then
			continue  # A long option we don't care about

		else  # Begins with a single dash, must be one or more short option(s)
			last_index=$(( ${#arg} - 1 ))

			for (( i=1; i <= last_index; i++ )); do
				ch=${arg:$i:1}

				if [[ $ch == "?" || $ch == "h" || $ch == "V" ]];
					then will_edit=false
				elif [[ $ch == "E" ]]; then
					tabstospaces=true
				elif [[ $ch == "T" ]]; then
					# If characters follow a T option, the rest of the arg is tab size, else the next arg is
					if (( i < last_index )); then
						tabsize="${arg:$i+1}"
					else
						tabsize_value_needed=true
					fi
				elif [[ "CQYors" == *$ch* ]]; then
					continue  # The rest of this argument, if any, is optarg
				fi
			done
		fi

		continue
	fi

	if [[ $arg == +* ]]; then
		# Nano appears to handle all arguments which begin with "+" the same way,
		# including plain "+", and things that are invalid as row/column notation like "+xyz"
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
	self="$0"
	while [[ -L $self ]]; do
		self="$(readlink "$self")"
	done

	if [[ $NICER_NANO_NO_EDITORCONFIG != true ]] && type -t editorconfig > /dev/null; then
		type -t use-editorconfig > /dev/null || source "$(dirname -- "$self")/functions/use-editorconfig.sh"
		use_editorconfig=true
	fi

	indent_conflict=false
	indent_style=""
	indent_size=""

	for file in "${files[@]}"; do
		[[ -n $file ]] || continue

		_indent_style="" _indent_size=""  # Assigned in use-editorconfig/detect-indent
		[[ $use_editorconfig == true ]] && use-editorconfig "$file"

		if [[ (-z $tabstospaces && -z $_indent_style) || (-z $tabsize && -z $_indent_size) ]]; then
			type -t detect-indent > /dev/null || source "$(dirname -- "$self")/functions/detect-indent.sh"
			detect-indent "$file"
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
			elif [[ "$indent_size" != "$_indent_size" &&
				($tabstospaces == true || "$indent_style" == "space") ]]
			then
				indent_conflict=true
				break
			fi
		fi
	done
fi

# Speak up if we've detected conflicting indentation styles
if [[ $indent_conflict == true ]]; then
	if [[ $indent_style == "tab" ]]; then
		blanket_indent="tabs"
	elif [[ -n $tabsize || -n $indent_size ]]; then
		blanket_indent="${tabsize:-$indent_size} spaces"
	else
		blanket_indent="spaces"
	fi

	if [[ -t 0 && -t 1 ]]; then
		terminal=true  # We'll prompt if stdin/stdout are connected to a terminal
		bright='\033[1m'
		normal='\033[0m'
	fi

	echo -e "${bright}Conflicting indentation settings were detected across different files.${normal}"
	echo "Nano uses the same indentation settings for all files loaded in a session,"
	echo "so it will indent newly-added lines with $blanket_indent in all of them."

	if [[ $terminal == true ]]; then
		echo -en "${bright}Continue [y|n]? ${normal}"
		read -rn 1
		echo
		[[ $REPLY == "Y" || $REPLY == "y" ]] || exit 0
	fi
fi

# Run nano
if [[ -z $tabstospaces &&
	($indent_style == "space" || ($indent_style == "" && $NICER_NANO_PREFER_SPACES == true)) ]]
then
	nano_args="--tabstospaces"
fi

if [[ -z $tabsize && -n $indent_size ]]; then
	[[ -z $nano_args ]] || nano_args+=" "
	nano_args+="--tabsize=$indent_size"
fi

if [[ $NICER_NANO_TESTING_CMD_LINE == true ]]; then
	echo "file names:    ${files[*]:--}"
	echo "will edit:     $will_edit"
	echo "\$tabstospaces: ${tabstospaces:--}"
	echo "\$tabsize:      ${tabsize:--}"
	cmd="echo"
elif [[ $NICER_NANO_TESTING_CONFLICTS == true ]]; then
	cmd="echo"
else
	cmd="exec"
fi

$cmd /usr/bin/nano $nano_args "$@"
