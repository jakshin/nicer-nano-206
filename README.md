# Nicer-than-default settings for GNU nano v2.0.6 on macOS

Apple ships a very old version of GNU nano on macOS, with very minimal configuration. It could easily be a bit nicer -- this repo tries to do that, in a way that makes installation a snap.

It's certainly possible to install the newest version of nano using [Homebrew](https://brew.sh), configure it, and then install online [syntax](https://github.com/scopatz/nanorc) [definitions](https://github.com/richrad/nanorc-mac), but sometimes that process feels heavyweight, especially if Homebrew isn't already installed, and/or if you only use nano occasionally anyway; as a lightweight alternative, **it's a one-liner in Terminal to install this repo's settings**.

You get some sensible default nano settings; cohesive syntax highighting in some common file types (based very loosely on the [Nord theme](https://www.nordtheme.com), and translated to the 16-color palette nano v2.0.6 supports); and an optional wrapper script for nano that can adjust its indentation settings on the fly, using either [EditorConfig](https://editorconfig.org) settings (if you have an `editorconfig` CLI installed), or by checking to see whether files being opened in nano are already indented with tabs or spaces.


## Installing and uninstalling

To **install**, just clone the repo and run its install script, i.e. run something like the following in Terminal/iTerm:   
`git clone https://github.com/jakshin/nicer-nano-206.git ~/.nicer-nano && ~/.nicer-nano/install.sh`

_(You can clone the repo anywhere you like, `~/.nicer-nano` is just an example.)_

To **uninstall** (i.e. remove the symlinks at `~/.nanorc` and `~/.nano-syntax`, and your local clone of the nicer-nano-206 repo), use the repo's uninstall script: `~/.nicer-nano/uninstall.sh`


## Using the nano wrapper script

The `nano206++.sh` file is a wrapper script, which passes its arguments to the real nano, after first trying to figure out the best indentation settings for the file(s) being edited, and adjusting nano's command line to tailor its indentation behavior to the situation at hand. It's intended to be symlinked as `/usr/local/bin/nano` so that when you invoke "nano", it runs instead of the real nano.

It first tries to use [EditorConfig](https://editorconfig.org) settings, as reported by the `editorconfig` CLI. This works on both existing and new files, since finding a relevant `.editorconfig` file only depends on the edited file's path. If the editorconfig CLI isn't installed, or no applicable `.editorconfig` is found, the script falls back to reading the file(s) being edited, and attempting to detect the indentation style already in use in the file; of course, that only works on files that already exist.

Take a look at the extensive comments at the top of [nano206++.sh](./scripts/nano206++.sh) for details, including ways to customize the script's behavior.


## Compatibility

To work on macOS's nano v2.0.6, these syntax definitions use `[[:<:]]` and `[[:>:]]` to match word boundaries (not  `\<` and `\>`, or `\b`), and `[[:space:]]` to match whitespace (not `\s`). Sadly, this makes them incompatible with recent versions of nano.
