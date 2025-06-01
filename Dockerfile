FROM ubuntu:24.04 AS neovim

ARG NEOVIM_VERSION=v0.11.1
ARG GO_VERSION=go1.24.3

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
  git curl zip unzip tar build-essential cmake \
  python3 python3-pip python3-venv \
  openjdk-21-jdk-headless maven \
  nodejs npm \
  ripgrep fd-find

# Install Treesitter CLI
RUN npm install -g tree-sitter-cli

# Install Go
RUN curl -fsSL https://go.dev/dl/${GO_VERSION}.linux-amd64.tar.gz -o /tmp/go-linux-amd64.tar.gz \
  && rm -rf /usr/local/go \
  && mkdir -p /usr/local/go \
  && tar -xzf /tmp/go-linux-amd64.tar.gz --strip-components=1 -C /usr/local/go \
  && find /usr/local/go/bin -type f -printf '%f\0' | xargs -i -0 ln -sf '../go/bin/{}' '/usr/local/bin/{}'

# Install latest stable Rust release
RUN curl -fsS --proto '=https' --tlsv1.2 https://sh.rustup.rs | sh -s -- --profile minimal -y

# Install Neovim
RUN curl -fsSL https://github.com/neovim/neovim/releases/download/${NEOVIM_VERSION}/nvim-linux-x86_64.tar.gz -o /tmp/nvim-linux-x86_64.tar.gz \
  && mkdir -p /opt/nvim \
  && tar -xzf /tmp/nvim-linux-x86_64.tar.gz --strip-components=1 -C /opt/nvim \
  && ln -s /opt/nvim/bin/nvim /usr/local/bin

# Switch to nonroot user
RUN useradd -ms /bin/bash nvimuser
USER nvimuser

ENV HOME=/home/nvimuser
ENV PATH=${PATH}:/usr/local/go/bin:${HOME}/.cargo/bin
ENV GOPATH=${HOME}/go
ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
ENV XDG_CONFIG_HOME=${HOME}/.config
ENV XDG_DATA_HOME=${HOME}/.local/share
ENV XDG_STATE_HOME=${HOME}/.local/state
ENV XDG_CACHE_HOME=${HOME}/.cache

# Set the current working directory
WORKDIR $HOME

# Use the previous image
FROM neovim AS builder

ARG CACHE_BUST=1

# Get config from dotfiles repo
RUN git clone --depth=1 https://github.com/emandret/dotfiles.git \
  && mkdir -p $XDG_CONFIG_HOME \
  && cp -r dotfiles/.config/nvim ${XDG_CONFIG_HOME}/nvim

# Install everything
COPY setup.lua .
RUN nvim --headless '+Lazy! sync' +qa \
  && nvim --headless '+luafile setup.lua'

# Package the config for offline use
RUN tar -czf /tmp/nvim-offline.tar.gz \
  -C $HOME .config/nvim .local/share/nvim

# Export stage
FROM scratch AS export
COPY --from=builder /tmp/nvim-offline.tar.gz /nvim-offline.tar.gz

