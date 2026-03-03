FROM ubuntu:24.04

# Base system packages and Haskell dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    ghc \
    cabal-install \
    libnuma-dev \
    libgmp-dev \
    libffi-dev \
    zlib1g-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/jgm/pandoc.git src && \
    cd src && \
    (git fetch --depth 1 origin b0aef22fe9a71297389968185ef44417046d6897 || git fetch --depth 1 origin "+refs/pull/10153/head:refs/remotes/origin/pr/10153") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Update cabal package database (fast operation)
RUN cabal update

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Don't build here - build will happen in test.sh
# This keeps the Docker build fast and moves compilation to test execution time

RUN rm -rf /app/src/.git

WORKDIR /app/src
