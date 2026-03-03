FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Haskell system dependencies (matching Dockerfile.build)
RUN apt-get update && apt-get install -y \
    libpq-dev \
    sqlite3 \
    libsqlite3-dev \
    libgmp3-dev \
    zlib1g-dev \
    llvm \
    cmake \
    llvm-dev \
    libnuma-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Install GHCup and Haskell toolchain (GHC 9.6.3)
ENV BOOTSTRAP_HASKELL_GHC_VERSION=9.6.3
ENV BOOTSTRAP_HASKELL_CABAL_VERSION=3.10.1.0
ENV BOOTSTRAP_HASKELL_NONINTERACTIVE=1
ENV BOOTSTRAP_HASKELL_INSTALL_NO_STACK=true
ENV BOOTSTRAP_HASKELL_INSTALL_NO_STACK_HOOK=true

RUN curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh

ENV PATH="/root/.cabal/bin:/root/.ghcup/bin:${PATH}"

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/simplex-chat/simplex-chat.git src && \
    cd src && \
    (git fetch --depth 1 origin 18302f5438a42ba3072359e0c0d374df0b3d4af8 || git fetch --depth 1 origin "+refs/pull/6411/head:refs/remotes/origin/pr/6411") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Update cabal package list
RUN cabal update

# Configure cabal for faster builds
RUN mkdir -p ~/.cabal && \
    echo "jobs: \$ncpus" >> ~/.cabal/config && \
    echo "documentation: False" >> ~/.cabal/config

# Build dependencies and test suite BEFORE applying patch (at HEAD state with fix)
# This allows Docker to cache this expensive layer
RUN cabal build simplex-chat-test --only-dependencies -j --ghc-options="-O0"

# Build the test suite at HEAD state
RUN cabal build simplex-chat-test -j --ghc-options="-O0"

# Reset to clean state before applying patch
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Rebuild only the affected modules (much faster than full rebuild)
RUN cabal build simplex-chat-test -j --ghc-options="-O0"

RUN rm -rf /app/src/.git

WORKDIR /app/src
