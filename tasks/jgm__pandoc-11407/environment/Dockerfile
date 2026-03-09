FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Haskell toolchain (ghcup, GHC, and Cabal)
RUN curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | \
    BOOTSTRAP_HASKELL_NONINTERACTIVE=1 BOOTSTRAP_HASKELL_MINIMAL=1 sh

ENV PATH="/root/.ghcup/bin:${PATH}"

# Install GHC 9.6 and Cabal 3.10 (matching requirements for pandoc 3.8.3)
RUN ghcup install ghc 9.6 && \
    ghcup set ghc 9.6 && \
    ghcup install cabal 3.10 && \
    ghcup set cabal 3.10

# Install system dependencies required for Haskell packages
RUN apt-get update && apt-get install -y \
    libnuma-dev \
    libgmp-dev \
    pkg-config \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/jgm/pandoc.git src && \
    cd src && \
    (git fetch --depth 1 origin 3feb1ba376402cd06cbec605c09c7a467075e2c1 || git fetch --depth 1 origin "+refs/pull/11407/head:refs/remotes/origin/pr/11407") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Update cabal package list
RUN cabal update

# Install dependencies for all packages in the project
RUN cabal build --dependencies-only --enable-tests --disable-optimization

# Build the project with tests enabled
RUN cabal build --enable-tests --disable-optimization

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly,
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Rebuild after applying bug.patch (Haskell is a compiled language)
RUN cabal build --enable-tests --disable-optimization

RUN rm -rf /app/src/.git

WORKDIR /app/src
