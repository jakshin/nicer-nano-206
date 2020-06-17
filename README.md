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

The `nano-smart-indent.sh` script is a wrapper for nano, which passes its arguments to nano, after first trying to figure out the best indentation settings for the file(s) being edited, and passing additional options to nano to adjust its indentation behavior as needed.

It first tries to use [EditorConfig](https://editorconfig.org) settings, as reported by the `editorconfig` CLI. This works on both existing and new files, since finding a relevant `.editorconfig` file only depends on the edited file's path. If the editorconfig CLI isn't installed, this step is skipped; if it is installed but you don't want this script to use it, you can put this line in your `~/.bashrc` and/or `~/.zshrc`: `export NANO_SMART_INDENT_NO_EDITORCONFIG=true`

If EditorConfig settings aren't found (or aren't used), the script next tries to read up to 20 KB from the file, and detect its indentation style. This, of course, only works on files that already exist.

For all of this to work, neither `/etc/nanorc` nor `~/.nanorc` can contain `set tabstospaces`; that's because nano doesn't provide a command-line option which tells it to use tabs for indentation, so if you've told it to use spaces for indentation in one of its config files, this script has no way to change that setting. And _that_, in turn, means that if this script can't detect a file's indentation style, nano's default setting of using tabs for indentation will come into play. If you're more a spaces-for-indentation kind of person, put this into your `~/.bashrc` and/or `~/.zshrc` to tell this script to default to having nano indent with spaces when it can't figure out what else to do: `export NANO_SMART_INDENT_PREFER_SPACES=true`

You can always pass `--tabstospaces` (or `-E`) if you want to indent a given file with spaces, and this script will dutifully pass that setting along to nano, regardless of what EditorConfig thinks or the indention style of any contents already in the file. You can also pass `--tabs`, which isn't an actual nano option, but which this script takes as the opposite of `--tabstospaces`, and which will make it _not_ tell nano to indent with spaces, regardless of EditorConfig's opinion, or an existing file's contents. If you pass both `--tabstospaces` and `--tabs`, `--tabstospaces` always wins, regardless of order.

The `--tabsize` (or `-T`) option is also passed through, setting the tab display width when indenting with tabs, or the number of spaces to use when indenting with spaces. If you don't pass it, either the relevant EditorConfig setting or the existing indentation width in the file will be used, or -- if neither of those are applicable/available -- the `tabsize` setting from nano's config file (4 in this repo's `nanorc`).


## Compatibility

To work on macOS's nano v2.0.6, these syntax definitions use `[[:<:]]` and `[[:>:]]` to match word boundaries (not  `\<` and `\>`, or `\b`), and `[[:space:]]` to match whitespace (not `\s`). Sadly, this makes them incompatible with recent versions of nano.
