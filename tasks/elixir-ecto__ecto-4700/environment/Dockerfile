FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Erlang and Elixir from Ubuntu repositories
# Ubuntu 24.04 has sufficiently recent versions that work with Ecto
RUN apt-get update && apt-get install -y \
    erlang \
    elixir \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/elixir-ecto/ecto.git src && \
    cd src && \
    (git fetch --depth 1 origin 46fd6f37b4a79c89879e848f67e11e3b5dcf2c51 || git fetch --depth 1 origin "+refs/pull/4700/head:refs/remotes/origin/pr/4700") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Set environment variables for test execution
ENV MIX_ENV=test

# Install hex and rebar (Elixir package managers)
RUN mix local.hex --force && \
    mix local.rebar --force

# Install dependencies
RUN mix deps.get && \
    mix deps.compile

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly,
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Elixir compiles on-the-fly, no rebuild needed after patching

RUN rm -rf /app/src/.git

WORKDIR /app/src
