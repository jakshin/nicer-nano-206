## Scripts

The `nano206++.sh` script is meant to be installed so that it gets invoked when you type "nano";
it acts just like nano itself, i.e. replaces itself with `/usr/bin/nano` and passes its arguments,
but first it checks for [EditorConfig](https://editorconfig.org) settings if it can,
and/or reads the files being loaded into nano to try to determine their existing indentation style,
and customizes nano's indentation behavior on the fly.

There are a few ways to manually install it.

The simplest way is to create a symlink somewhere in your `$PATH` before `/usr/bin`,
like `/usr/local/bin`, but note that if have Homebrew's nano installed, or install it later,
that nano will also want to be `/usr/local/bin/nano`. Another option is installing it into `~/bin`,
and ensuring that directory is mentioned in your `$PATH` before `/usr/bin` (unlike `/usr/local/bin`,
it isn't in `$PATH` by default).

Another option is to make an alias or function:

```sh
# These are functionally equivalent
alias nano=/path/to/here/nano206++.sh
nano() { /path/to/here/nano206++.sh "$@"; }
```

This will avoid conflicts with other versions of nano, but note that `nano206++.sh` won't get invoked
when a program such as Git runs nano for you through `$VISUAL` or `$EDITOR` (which might be just fine).

Whichever way `nano206++.sh` is installed, note that in order for it to work correctly,
neither of nano's configuration files (`/etc/nanorc` and `~/.nanorc`) can contain `set tabstospaces`.
To use the wrapper script and still default to indenting with spaces, put this in your shell startup files:

```sh
export NICER_NANO_PREFER_SPACES=true
```