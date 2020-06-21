#!/bin/bash -e
# Copyright (c) 2020 Jason Jackson. MIT License.

## Configures nicer settings for nano, by creating/removing various symlinks,
## and editing ~/.bashrc and/or ~/.zshrc (backups are created first).
## This is only intended for use on macOS with GNU nano v2.0.6.
##
## Usage: configure.sh
##
## You'll be asked which settings you'd like to install (or uninstall),
## and prompted before replacing any existing files.

if [[ $1 == "-h" || $1 == "--help" ]]; then
	grep -E "^##" "$0" | sed -E 's/## ?//'
	exit
fi

# Run from this script's directory
cd -- "$(dirname "$0")"
script_dir="$(pwd -P)"
repo_dir="$(basename -- "$script_dir")"  # Just the name of the directory, not the whole path

# Utilities
bright_color='\033[1m'
cmd_color='\033[38;5;240m'
header_color='\033[38;5;99m'  # Nano's website uses purple, so eh
no_color='\033[0m'

backup_extension="nicer-nano-backup"

function back-up() {
	# Backs up a file by copying it (copying a symlink as a symlink)
	local file_path="$1"
	local preserve_symlink="$2"  # Optional boolean

	[[ -f $file_path || -L $file_path ]] || return 1

	local backup_path="${file_path}.${backup_extension}"
 	if [[ ! -e $backup_path && ! -L $backup_path ]]; then
		[[ $preserve_symlink == true ]] && preserve_symlink="-R"
		echo-cmd cp $preserve_symlink "${file_path//$HOME/~}" "${backup_path//$HOME/~}"
		cp $preserve_symlink "$file_path" "$backup_path"
	fi
}

function echo-cmd() {
	echo -e "${cmd_color}▶ ${*}${no_color}"
}

function echo-header() {
	echo -e "\n${header_color}${*}${no_color}"
}

function echo-wrapped() {
	# Like echo, but with word wrap
	if [[ $COLUMNS =~ ^[0-9]+$ ]]; then
		local width=$(( COLUMNS - 4 ))
		(( width <= 88 )) || width=88
	else
		local width=76
	fi

	if which "fmt" &> /dev/null; then
		echo "${*}" | fmt -w $width
	elif which "fold" &> /dev/null; then
		echo "${*}" | fold -sw $width
	else
		echo "${*}"
	fi
}

function make-dir() {
	# Makes a directory recursively, using sudo iff needed
	local dir_path="$1"

	local dir_parts partial_path="" writable=false old_IFS="$IFS" IFS='/'
	dir_parts=($dir_path)  # Split on slashes (if absolute path, first array element is empty)
	IFS="$old_IFS"

	for dir in "${dir_parts[@]}"; do
		[[ -n $dir ]] || continue
		partial_path+="/$dir"
		[[ -e $partial_path ]] || break
		[[ -w $partial_path ]] && writable=true || writable=false
	done

	local sudo="sudo"
	[[ $writable == true ]] && sudo=""

	echo-cmd $sudo mkdir -p "$dir_path"
	$sudo mkdir -p "$dir_path"
}

function prompt() {
	# Asks a question and prompts for a Y/N answer
	local question="$1"

	unset REPLY  # Return value

	while [[ -z $REPLY || "yn" != *"$REPLY"* ]]; do
		echo -en "${bright_color}${question} [y|n] ${no_color}"
		read -rn 1
		echo && echo  # Blank line after responding
		REPLY="$(echo "$REPLY" | awk '{ print tolower($1) }')"
	done
}

function remove-empty-line() {
	# Removes a line from a shell rc file, iff it's empty
	local rc_file="$1"
	local line_num="$2"

	while [[ -L $rc_file ]]; do
		rc_file="$(readlink "$rc_file")"
	done

	sed -i '' "$line_num{/^$/d;}" "$rc_file"
}

function remove-setting() {
	# Removes a setting from a shell rc file
	local rc_file="$1"
	local setting_regex="$2"

	if grep -Eq "$setting_regex" "$rc_file"; then
		back-up "$rc_file"
		echo-cmd "${rc_file//$HOME/~}: REMOVE $setting_regex"

		while [[ -L $rc_file ]]; do
			rc_file="$(readlink "$rc_file")"
		done

		grep -Eiv "$setting_regex" "$rc_file" > "$rc_file.nicer-nano-tmp"
		mv -f "$rc_file.nicer-nano-tmp" "$rc_file"
	fi
}

function save-setting() {
	# Adds a setting to a shell rc file, just after the "settings for nicer-nano" comment,
	# first adding that comment if it's not found
	local rc_file="$1"
	local setting_line="$2"

	if ! grep -Fq "$setting_line" "$rc_file"; then
		if ! grep -Fiq "settings for nicer-nano" "$rc_file"; then
			back-up "$rc_file"
			[[ -s $rc_file ]] && echo >> "$rc_file"
			echo "# Settings for nicer-nano" >> "$rc_file"
		fi

		back-up "$rc_file"
		echo-cmd "${rc_file//$HOME/~}: ADD $setting_line"

		while [[ -L $rc_file ]]; do
			rc_file="$(readlink "$rc_file")"
		done

		sed -i '' $'/#.*nicer-nano/a\\\n'"$setting_line"$'\n' "$rc_file"
	fi
}

function symlink() {
	# Creates a symlink to a target, backing up an existing file if needed
	local link_path="$1"
	local target_path="$2"

	local sudo="sudo"
	[[ -w "$(dirname -- "$link_path")" ]] && sudo=""

	if [[ -L $link_path ]]; then
		local linked_to="$(readlink "$link_path")"
		if [[ $linked_to != *"/$repo_dir/"* && $linked_to != *"nicer-nano"* ]]; then
			back-up "$link_path" true
		fi
	elif [[ -e $link_path ]]; then
		back-up "$link_path"
	fi

	rm -f "$link_path"
	echo-cmd $sudo ln -s "${target_path//$HOME/~}" "${link_path//$HOME/~}"
	$sudo ln -s "$target_path" "$link_path"
}

function unsymlink() {
	# Removes a symlink, restoring a backup file if one is found
	local link_path="$1"

	local sudo="sudo"
	[[ -w "$(dirname -- "$link_path")" ]] && sudo=""

	if [[ -L $link_path ]]; then
		local linked_to="$(readlink "$link_path")"
		if [[ $linked_to == *"/$repo_dir/"* || $linked_to == *"nicer-nano"* ]]; then
			echo-cmd $sudo rm -f "${link_path//$HOME/~}"
			$sudo rm -f "$link_path"
		fi
	fi

	# If there's a backup, ask whether to rename it back into place
	local backup_path="${link_path}.${backup_extension}"
	if [[ -e $backup_path || -L $backup_path ]]; then
		echo -e "\nFound $backup_path"
		prompt "Rename it back to $link_path?"

		if [[ $REPLY == "y" ]]; then
			echo-cmd $sudo mv "${backup_path//$HOME/~}" "${link_path//$HOME/~}"
			$sudo mv "$backup_path" "$link_path"
		fi
	fi
}

# Install/uninstall things
echo -e "${header_color}~~~ CONFIGURING NICER-NANO ~~~${no_color}"

settings_in_bashrc=false
settings_in_zshrc=false

echo-header "Use nano configuration and syntax definitions?"
echo-wrapped "Symlinks will be created at ~/.nanorc and ~/.nano-syntax."
prompt "Are you into that idea?"

if [[ $REPLY == "y" ]]; then
	symlink ~/.nanorc "$script_dir/cfg/nanorc"
	symlink ~/.nano-syntax "$script_dir/syntax"
else
	unsymlink ~/.nanorc
	unsymlink ~/.nano-syntax
fi

echo-header "Use bash completions for nano?"
echo-wrapped "You'll be able to type 'nano -' and press <tab> in bash to auto-complete nano's options." \
	"A line will be added to your ~/.bashrc to enable the completions."
prompt "Sound good to you?"

existing_setting_regex="(nicer-nano|$repo_dir).*nano\.bash"

if [[ $REPLY == "y" ]]; then
	comp_path="${script_dir//$HOME/~}/completions/nano.bash"
	[[ $comp_path == ~* ]] && comp_path="~/\"${comp_path:2}\"" || comp_path="\"$comp_path\""

	remove-setting ~/.bashrc "$existing_setting_regex"
	save-setting ~/.bashrc "source $comp_path &> /dev/null"
	settings_in_bashrc=true
else
	remove-setting ~/.bashrc "$existing_setting_regex"
fi

zsh_completions_dir="$(zsh -c 'echo $fpath[1]')"
[[ -n $zsh_completions_dir ]] || zsh_completions_dir='/usr/local/share/zsh/site-functions'

echo-header "Use zsh completions for nano?"
echo-wrapped "You'll be able to type 'nano -' and press <tab> in zsh to auto-complete nano's options." \
	"A symlink will be created at $zsh_completions_dir/_nano to enable the completions."
prompt "Sound nice to have?"

if [[ $REPLY == "y" ]]; then
	make-dir "$zsh_completions_dir"
	symlink "$zsh_completions_dir/_nano" "$script_dir/completions/nano.zsh"
else
	unsymlink "$zsh_completions_dir/_nano"
fi

echo-header "Use the nano wrapper script?"
echo-wrapped "The nano206++.sh wrapper script takes over when you run 'nano' at a command line" \
	"(or a program like Git runs it for you). It works just like the real nano does," \
	"but it also configures nano's indentation settings on the fly, using EditorConfig" \
	"and/or by detecting existing indentation in the file(s) you edit." \
	"A symlink will be created at /usr/local/bin/nano to enable the script."
prompt "You want?"

if [[ $REPLY == "y" ]]; then
	make-dir "/usr/local/bin"
	symlink "/usr/local/bin/nano" "$script_dir/scripts/nano206++.sh"
else
	unsymlink "/usr/local/bin/nano"
fi

if [[ "$(type nano)" == *"nano206++"* ]]; then
	nano_wrapper=true
else
	nano_cmd="$(type -p nano)"
	if [[ -L $nano_cmd && "$(readlink "$nano_cmd")" == *"nano206++.sh"* ]]; then
		nano_wrapper=true
	fi
fi

if [[ $nano_wrapper == true ]]; then
	echo-header "Do you prefer to indent with tabs or spaces?"
	echo-wrapped "In the absence of info from EditorConfig or existing indentation in files," \
		"nano206++.sh can default to indenting with tabs or spaces. If you prefer spaces," \
		"a line can be added to your ~/.bashrc and ~/.zshrc to activate that setting."
	prompt "Indent with spaces by default?"

	if [[ $REPLY == "y" ]]; then
		save-setting ~/.bashrc "export NICER_NANO_PREFER_SPACES=true"
		save-setting ~/.zshrc "export NICER_NANO_PREFER_SPACES=true"
		settings_in_bashrc=true
		settings_in_zshrc=true
	else
		remove-setting ~/.bashrc "NICER_NANO_PREFER_SPACES"
		remove-setting ~/.zshrc "NICER_NANO_PREFER_SPACES"
	fi
else
	remove-setting ~/.bashrc "NICER_NANO_PREFER_SPACES"
	remove-setting ~/.zshrc "NICER_NANO_PREFER_SPACES"
fi

# If we removed all settings from either ~/.bashrc or ~/.zshrc,
# also remove its "settings for nicer-nano" comment
function clean-up-rc-file() {
	local rc_file="$1"

	local line_num
	line_num="$(grep -n nicer-nano "$rc_file" | awk -F: '{print $1}' || true )"

	if [[ -n $line_num ]]; then
		remove-setting "$rc_file" "#.*nicer-nano"
		remove-empty-line "$rc_file" "$(( line_num - 1 ))"
		removed=true
	fi
}

[[ $settings_in_bashrc == true ]] || clean-up-rc-file ~/.bashrc
[[ $settings_in_zshrc == true ]] || clean-up-rc-file ~/.zshrc
[[ $removed == true ]] || echo-cmd "Lookin' good here"

echo-header "~~~ ALL DONE ~~~"
