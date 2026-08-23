.PHONY: neovim archive test clean

PLATFORMS ?= linux/amd64,linux/arm64
OUT_DIR   ?= ./out

neovim:
	docker buildx build \
		--target neovim \
		--tag neovim:latest \
		--load \
		.

archive:
	docker buildx build \
		--platform $(PLATFORMS) \
		--target archive \
		--output type=local,dest=$(OUT_DIR) \
		--build-arg CACHE_BUST=$$(date +%s) \
		.

test: neovim archive
	chmod 777 $(OUT_DIR)
	docker run --rm -it -v $(OUT_DIR):/tmp/out neovim:latest bash -c \
		'tar -xzf /tmp/out/nvim-offline.tar.gz -C ~ && nvim'

clean:
	rm -rf $(OUT_DIR)
	docker image rm neovim:latest 2>/dev/null || true
