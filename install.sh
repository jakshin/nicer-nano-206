#!/bin/bash -e
# Installs nicer settings for macOS's nano, by creating various symlinks.
# This is only intended for use on macOS with GNU nano v2.0.6.

# FIXME install.sh -> create ~/.nanorc and ~/.nano-syntax symlinks,
# detecting existing files/symlinks

# FIXME also bash & zsh completions

# FIXME also an alias for nano-smart-indent.sh...
# but an alias won't work when other programs launch nano, e.g. git,
# so maybe either also set $EDITOR / $VISUAL if they mention nano,
# or use a symlink in /usr/local/bin instead (refusing to replace anything already there)

# # Initialize
# cd -- "$(dirname -- "$0")"  # Run from this script's directory
# script_dir="$(pwd -P)"
# source "$script_dir/../scripts/bash-utils.sh"
# show_help_if_requested "$@"

# # Create symlinks
# last_was_installed=false

# install_file "$script_dir/nanorc" ~/.nanorc "first"
# install_file "$script_dir/syntax" ~/.nano-syntax

# [[ $last_was_installed == true ]] || echo
# echo "Done"
