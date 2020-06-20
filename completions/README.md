## Bash & Zsh Completions

These files allow nano's options to be auto-completed at a bash/zsh command line.
Once installed, type `nano -` or `nano --` and then press `<tab>` to use them.

Manual installation:

* You need to source `nano.bash` to get the completions working in bash;
  the simplest way to do so in vanilla macOS is by doing so in your `~/.bashrc`.

* For completions in zsh, you only need to copy or symlink `nano.zsh`, as `_nano`,
  to a file in your `$fpath` -- `$fpath[1]`, i.e. `/usr/local/share/zsh/site-functions`,
  is likely the best option (even if you need to create that directory first).
