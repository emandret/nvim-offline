FROM ubuntu:24.04 AS neovim
# TARGETARCH is automatically set by buildkit per --platform target
ARG TARGETARCH
ARG NVIM_VERSION=v0.11.3
ARG GO_VERSION=go1.24.5

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
  git curl zip unzip tar \
  ninja-build build-essential cmake meson \
  pkg-config autoconf automake libtool \
  openssl libssl-dev \
  python3 python3-pip python3-venv \
  openjdk-21-jdk-headless maven \
  nodejs npm \
  ripgrep fd-find

# Install treesitter CLI
RUN npm install -g tree-sitter-cli

# Install Go
RUN curl -fsSL https://go.dev/dl/${GO_VERSION}.linux-${TARGETARCH}.tar.gz -o /tmp/go-linux-${TARGETARCH}.tar.gz \
  && rm -rf /usr/local/go \
  && mkdir -p /usr/local/go \
  && tar -xzf /tmp/go-linux-${TARGETARCH}.tar.gz --strip-components=1 -C /usr/local/go \
  && find /usr/local/go/bin -type f -printf '%f\0' | xargs -i -0 ln -sf '../go/bin/{}' '/usr/local/bin/{}'

# Install Neovim
RUN case "${TARGETARCH}" in \
      amd64) NVIM_ARCH=x86_64 ;; \
      arm64) NVIM_ARCH=arm64 ;; \
      *) echo "Unsupported architecture: ${TARGETARCH}" && exit 1 ;; \
    esac \
  && curl -fsSL https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux-${NVIM_ARCH}.tar.gz -o /tmp/nvim-linux.tar.gz \
  && mkdir -p /opt/nvim \
  && tar -xzf /tmp/nvim-linux.tar.gz --strip-components=1 -C /opt/nvim \
  && ln -s /opt/nvim/bin/nvim /usr/local/bin

# Switch to nonroot user
RUN useradd -ms /bin/bash nvimuser
USER nvimuser

# Install latest stable Rust release (rustup autodetects arch)
RUN curl -fsS --proto '=https' --tlsv1.2 https://sh.rustup.rs | sh -s -- --profile minimal -y \
  && . ${HOME}/.cargo/env

ENV HOME=/home/nvimuser
ENV PATH=${PATH}:/usr/local/go/bin:${HOME}/.cargo/bin
ENV GOPATH=${HOME}/go
ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk-${TARGETARCH}
ENV XDG_CONFIG_HOME=${HOME}/.config
ENV XDG_DATA_HOME=${HOME}/.local/share
ENV XDG_STATE_HOME=${HOME}/.local/state
ENV XDG_CACHE_HOME=${HOME}/.cache
WORKDIR $HOME

# Everything below reruns everytime CACHE_BUST changes
ARG CACHE_BUST=1

RUN git clone --depth=1 https://github.com/emandret/dotfiles.git \
  && mkdir -p $XDG_CONFIG_HOME \
  && cp -r dotfiles/.config/nvim ${XDG_CONFIG_HOME}/nvim \
  && rm -f ${XDG_CONFIG_HOME}/nvim/lazy-lock.json

COPY setup.lua .
RUN nvim --headless '+Lazy! sync' +qa \
  && nvim --headless '+luafile setup.lua'

RUN tar -czf /tmp/nvim-offline.tar.gz \
-C $HOME .config/nvim .local/share/nvim

FROM scratch AS archive
COPY --from=neovim /tmp/nvim-offline.tar.gz /nvim-offline.tar.gz
