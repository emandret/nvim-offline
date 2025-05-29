# Neovim offline installation

This Dockerfile will produce a fully self-contained Neovim installation archive, which can then be copied into an air-gapped machine, and extracted.

Create the archive:
```
docker build --target export --output type=local,dest=./out --build-arg CACHE_BUST=$(date +%s) .
```

Extract on the target machine with:
```
tar -xzf nvim-offline.tar.gz -C ~
```
