# Nicer-than-default settings for GNU nano v2.0.6 on macOS

Apple ships a very old version of GNU nano on macOS, with minimalist settings.

Of course it's possible to install the newest version of nano using [Homebrew](https://brew.sh), configure it, and then grab online [syntax](https://github.com/scopatz/nanorc) [definitions](https://github.com/richrad/nanorc-mac), but sometimes that process feels like a hassle (install Homebrew, install nano, install and maybe tweak syntax definitions), especially if you only use nano occasionally; as a lightweight alternative, it's a one-liner to install this repo's settings to make macOS's nano a bit nicer.

You get some sensible default settings; cohesive syntax highighting in common file types (based very loosely on the [Nord theme](https://www.nordtheme.com), and translated to the 16-color palette nano v2.0.6 supports); and an optional wrapper script for nano that can adjust nano's indentation settings on the fly, using either [EditorConfig](https://editorconfig.org) - if you have an `editorconfig` CLI installed - or by checking to see whether files being opened in nano are already indented with tabs or spaces.


## Installing and Uninstalling

To **install**, just clone the repo and run its install script, i.e. run something like the following in Terminal.app:   
`git clone https://github.com/jakshin/nicer-nano-206.git ~/.nicer-nano && ~/.nicer-nano/install.sh`

_(You can clone the repo anywhere you like, `~/.nicer-nano` is just an example.)_

To **uninstall** (i.e. remove the symlinks at `~/.nanorc` and `~/.nano-syntax`, and your local clone of the nicer-nano-206 repo), use the repo's uninstall script: `~/.nicer-nano/uninstall.sh`


## Compatibility

To work on macOS's nano v2.0.6, these syntax definitions use `[[:<:]]` and `[[:>:]]` to match word boundaries (not  `\<` and `\>`, or `\b`), and `[[:space:]]` to match whitespace (not `\s`). Sadly, this makes them incompatible with recent versions of nano.
