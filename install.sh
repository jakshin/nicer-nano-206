#!/bin/bash -e
# Installs nicer settings for macOS's nano, by creating links at ~/.nanorc and ~/.nano-syntax.
# This is only intended for use on macOS with GNU nano v2.0.6.

# FIXME implement
# install.sh -> create symlinks with replacement detection,
# offer to add aliases to ~/.bashrc and/or ~/.zshrc if they're not already there

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
