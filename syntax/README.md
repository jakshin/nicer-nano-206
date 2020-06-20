## Syntax Definitions

These syntax definitions provide highlighting for file types it seems likely casually edit in nano.   
They're referenced in this repo's [configuration file](../cfg), so they should be installed with it.   
To manually install both:

```sh
# Run this in the repo's root directory
ln -sv "$PWD/cfg/nanorc" ~/.nanorc
ln -sv "$PWD/syntax" ~/.nano-syntax
```

Or you can just install these syntax definitions by creating the second symlink above,
then copy-pasting the "Syntax highlighting" block from this repo's [nanorc](../cfg/nanorc)
into your own `~/.nanorc`.
