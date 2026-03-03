FROM ubuntu:24.04

# Set locale to UTF-8 (required for Haskell happy parser)
RUN apt-get update && apt-get install -y locales && \
    locale-gen en_US.UTF-8 && \
    rm -rf /var/lib/apt/lists/*
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install dependencies for Haskell/Stack/GHC
RUN apt-get update && apt-get install -y \
    wget \
    libnuma-dev \
    libgmp-dev \
    libtinfo-dev \
    zlib1g-dev \
    libffi-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Stack 2.9.3
RUN apt-get update && curl -sSL https://get.haskellstack.org/ | sh -s - -d /usr/local/bin && \
    rm -rf /var/lib/apt/lists/*

# Install Node.js 16 for running tests
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/purescript/purescript.git src && \
    cd src && \
    (git fetch --depth 1 origin 16fd7f256954ea72d7e87c8b9ec659eba0fabf66 || git fetch --depth 1 origin "+refs/pull/4536/head:refs/remotes/origin/pr/4536") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Install npm dependencies for tests
RUN cd tests/support && npm install && \
    npx bower --allow-root install --config.interactive=false

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

RUN rm -rf /app/src/.git

WORKDIR /app/src
