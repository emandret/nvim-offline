# Neovim offline installation

This Dockerfile will produce a fully self-contained Neovim installation archive, which can then be copied into an air-gapped machine, and extracted.

Create the archive:

```sh
docker build --target neovim -t neovim:latest .
docker build --target export --output type=local,dest=./out --build-arg CACHE_BUST=$(date +%s) .
```

Try it:

```sh
chmod 777 ./out
docker run --rm -it --name neovim-test -v ./out:/tmp/out neovim:latest bash
$ tar -xzf /tmp/out/nvim-offline.tar.gz -C ~
$ nvim
```

## Fix homedir path after installation

If your homedir path is different, you can use this command to change it after installation:

```sh
grep -IRli '/home/nvimuser' ~/.local/share/nvim | xargs -n1 sed -i 's|/home/nvimuser|/home/admin|g'
```
