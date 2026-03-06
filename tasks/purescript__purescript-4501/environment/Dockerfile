FROM ubuntu:24.04

# Base system packages
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install additional system packages for Haskell/GHC
RUN apt-get update && apt-get install -y \
    zlib1g-dev \
    libtinfo-dev \
    libgmp-dev \
    libffi-dev \
    libncurses-dev \
    wget \
    locales \
    netbase \
    && rm -rf /var/lib/apt/lists/*

# Set up locale
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

# Install Stack (Haskell build tool)
RUN curl -sSL https://get.haskellstack.org/ | sh

# Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/purescript/purescript.git src && \
    cd src && \
    (git fetch --depth 1 origin 45884009d63f8f70d7e39c9cee8bf078906a58c9 || git fetch --depth 1 origin "+refs/pull/4501/head:refs/remotes/origin/pr/4501") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Build with Stack
RUN stack setup && stack build --fast --test --only-dependencies

# Reset files before applying bug patch
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Rebuild after patching
RUN stack build --fast --test --no-run-tests

RUN rm -rf /app/src/.git

WORKDIR /app/src
