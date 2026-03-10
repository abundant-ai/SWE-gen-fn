FROM ubuntu:24.04

# Base system packages and Haskell dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    libgmp-dev \
    zlib1g-dev \
    libtinfo-dev \
    libncurses5-dev \
    libffi-dev \
    wget \
    locales \
    && rm -rf /var/lib/apt/lists/*

# Set up UTF-8 locale for proper encoding handling
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# Install GHCup, GHC, and Cabal
RUN curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | \
    BOOTSTRAP_HASKELL_NONINTERACTIVE=1 \
    BOOTSTRAP_HASKELL_GHC_VERSION=recommended \
    BOOTSTRAP_HASKELL_CABAL_VERSION=recommended \
    BOOTSTRAP_HASKELL_INSTALL_STACK=1 \
    BOOTSTRAP_HASKELL_ADJUST_BASHRC=1 \
    sh

ENV PATH="/root/.ghcup/bin:/root/.cabal/bin:${PATH}"

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/simonmichael/hledger.git src && \
    cd src && \
    (git fetch --depth 1 origin 901481ac1df46b18a82b2c7fc2f257deebb700f7 || git fetch --depth 1 origin "+refs/pull/2412/head:refs/remotes/origin/pr/2412") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Update cabal package list
RUN cabal update

# Build and install hledger with minimal flags for speed
RUN cabal install --jobs=$(nproc) --installdir=/root/.local/bin --install-method=copy --overwrite-policy=always \
    --ghc-options="-j$(nproc)" \
    hledger

# Install shelltestrunner for running functional tests
RUN cabal install --jobs=$(nproc) --installdir=/root/.local/bin --install-method=copy --overwrite-policy=always \
    shelltestrunner-1.11

ENV PATH="/root/.local/bin:${PATH}"

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly,
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Rebuild after applying bug.patch (Haskell is compiled)
RUN cabal install --jobs=$(nproc) --installdir=/root/.local/bin --install-method=copy --overwrite-policy=always \
    --ghc-options="-j$(nproc)" \
    hledger

RUN rm -rf /app/src/.git

WORKDIR /app/src
