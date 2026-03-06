FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install additional system packages for Haskell/PureScript
RUN apt-get update && apt-get install -y \
    zlib1g-dev \
    libtinfo-dev \
    libgmp-dev \
    libffi-dev \
    libncurses-dev \
    wget \
    locales \
    netbase \
    xz-utils \
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

# Set Stack environment variables to avoid tar issues
ENV STACK_ROOT=/root/.stack

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/purescript/purescript.git src && \
    cd src && \
    (git fetch --depth 1 origin a09f900c56f56f662902e47f2921622f8adff6de || git fetch --depth 1 origin "+refs/pull/4374/head:refs/remotes/origin/pr/4374") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Build with Stack
RUN stack setup && stack build --fast --test --only-dependencies
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Rebuild after patching
RUN stack build --fast --test --no-run-tests

RUN rm -rf /app/src/.git

WORKDIR /app/src
