FROM ubuntu:22.04 AS builder

ARG NEOVIM_VERSION=v0.11.1

# Install system dependencies
RUN apt-get update && apt-get install -y \
  git curl unzip tar build-essential \
  python3 python3-pip nodejs npm \
  ripgrep fd-find

# Install latest Neovim release
RUN curl -fsSL https://github.com/neovim/neovim/releases/download/$NEOVIM_VERSION/nvim-linux-x86_64.tar.gz -o /tmp/nvim-linux-x86_64.tar.gz \
  && mkdir -p /opt/nvim \
  && tar -xzf /tmp/nvim-linux-x86_64.tar.gz --strip-components=1 -C /opt/nvim \
  && ln -s /opt/nvim/bin/nvim /usr/local/bin/nvim

# Switch to nonroot user
RUN useradd -ms /bin/bash nvimuser
USER nvimuser

ENV HOME=/home/nvimuser
ENV XDG_CONFIG_HOME=$HOME/.config
ENV XDG_DATA_HOME=$HOME/.local/share
ENV XDG_STATE_HOME=$HOME/.local/state
ENV XDG_CACHE_HOME=$HOME/.cache

# Set the current working directory
WORKDIR $HOME

# Get config from dotfiles repo
ARG CACHE_BUST=1
RUN git clone --depth=1 https://github.com/emandret/dotfiles.git \
  && mkdir -p $XDG_CONFIG_HOME \
  && cp -r dotfiles/.config/nvim $XDG_CONFIG_HOME/nvim

# Install everything
COPY mason_install.lua .
RUN nvim --headless '+Lazy! sync' +qa \
  && nvim --headless +TSUpdateSync +qa \
  && RUN nvim --headless '+luafile mason_install.lua'

# Package the config for offline use
RUN tar -czf /tmp/nvim-offline.tar.gz \
  -C $HOME .config/nvim .local/share/nvim

# Export stage
FROM scratch AS export
COPY --from=builder /tmp/nvim-offline.tar.gz /nvim-offline.tar.gz
