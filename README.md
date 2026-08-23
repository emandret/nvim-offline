# Neovim offline installation

Produce a fully self-contained Neovim archive, which can be copied to a target machine.

```sh
make archive
```

## Fix homedir path after installation

If your homedir path is different, you can use this command to change it after installation:

```sh
\grep -IRli '/home/nvimuser' ~/.local/share/nvim | xargs -n1 sed -i 's|/home/nvimuser|/home/admin|g'
```
