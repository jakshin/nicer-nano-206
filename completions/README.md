## Bash & Zsh Completions

These files allow nano's options to be auto-completed at a bash/zsh command line.   
Once installed, type `nano -` or `nano --` and then press `<tab>` to use them.

To manually install the completions for bash, you need to source `nano.bash`;   
the simplest way to do so in vanilla macOS is by adding a line to your `~/.bashrc`:

```sh
source "/path/to/here/nano.bash"
```

To manually install the completions for zsh, you only need to copy or symlink `nano.zsh`
as `_nano` (or it won't work), to a directory in your `$fpath`. The best best is likely `$fpath[1]`,
i.e. `/usr/local/share/zsh/site-functions`, even if you need to create that directory first.
