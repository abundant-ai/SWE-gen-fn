FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Haskell toolchain (GHC and Stack) with locale support
RUN apt-get update && apt-get install -y \
    haskell-stack \
    locales \
    && rm -rf /var/lib/apt/lists/*

# Set up UTF-8 locale to avoid encoding issues during build
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8

# Install PostgreSQL server and client libraries
RUN apt-get update && apt-get install -y \
    postgresql \
    postgresql-contrib \
    libpq-dev \
    zlib1g-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/PostgREST/postgrest.git src && \
    cd src && \
    (git fetch --depth 1 origin da77973a908a3688744b94bd61ee82bec10151af || git fetch --depth 1 origin "+refs/pull/4561/head:refs/remotes/origin/pr/4561") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Set up Stack configuration
ENV STACK_ROOT=/root/.stack

# Install Haskell dependencies (using --fast to speed up compilation)
RUN stack setup && \
    stack build --fast --test --only-dependencies

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly,
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Dependencies don't change, no need to rebuild them after patching

RUN rm -rf /app/src/.git

WORKDIR /app/src
