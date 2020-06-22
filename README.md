# Nicer-than-default settings for GNU nano v2.0.6 on macOS

Apple ships a very old version of GNU nano on macOS, with very minimal configuration. It could easily be a bit nicer -- this repo tries to do that, in a way that makes installation a snap. In fact, it can be installed with a **single line of shell script**.

And what do you get for the low, low price of copy-pasting a single line into your terminal?   
How about these fine features:

* Humane default settings for nano
* Cohesive syntax highighting in some common file types (based very loosely on the [Nord theme](https://www.nordtheme.com), and translated to the 16-color palette nano v2.0.6 supports)
* Bash and zsh completions for nano's options (with a handy description of each option, in zsh)

But wait, there's more!

* And an optional wrapper script for nano that adjust its indentation settings on the fly, using either [EditorConfig](https://editorconfig.org) settings (if you have an `editorconfig` CLI installed), or by checking to see whether files being opened in nano are already indented with tabs or spaces -- now it can be as unlikely to mis-indent a file in nano as in any other editor

* Act now and at no additional cost to you, the wrapper script will also automatically enable spell-checking in nano, if you have a compatible spell-checker installed (aspell, hunspell, or ispell -- all of which are available from [Homebrew](https://brew.sh))

_You're gonna have an exciting life now!_


## Installing and uninstalling

To **install**, just clone the repo and run its configuration script in Terminal:   
`git clone https://github.com/jakshin/nicer-nano-206.git ~/.nicer-nano && ~/.nicer-nano/configure.sh`

_(You can clone the repo anywhere you like, `~/.nicer-nano` is just an example. And if you prefer manual installation, there are instructions in each subdirectory's README.md.)_

To **uninstall**, run `configure.sh` again and say No to each option, then delete your clone of the repo. Depending on which options you installed, you might also have backups of your `~/.bashrc` and/or `~/.zshrc` files, with a `.nicer-nano-backup` extension, which you may want to delete.


## Using the nano wrapper script

The `nano206++.sh` script is a wrapper for nano, which passes its arguments to the real nano, after first (1) trying to figure out the best indentation settings for the file(s) being edited, and adjusting nano's command line to tailor its indentation behavior to the situation at hand; and (2) checking for the presence of a spell-checker, and if one is found, automatically configuring nano to use it.

It's intended to be symlinked as `/usr/local/bin/nano` so that when you invoke "nano", it runs instead of the real nano. Once it's installed, just run `nano ...` like you normally would.

For more details, including ways to customize its behavior, take a look at the extensive comments at the top of [nano206++.sh](./scripts/nano206++.sh).


## Compatibility

To work on macOS's nano v2.0.6, these syntax definitions use `[[:<:]]` and `[[:>:]]` to match word boundaries (not  `\<` and `\>`, or `\b`), and `[[:space:]]` to match whitespace (not `\s`). Sadly, this makes them incompatible with recent versions of nano.

<!--
Other collections of syntax definitions, for more recent nano versions:
https://github.com/scopatz/nanorc
https://github.com/richrad/nanorc-mac (themed)
-->
