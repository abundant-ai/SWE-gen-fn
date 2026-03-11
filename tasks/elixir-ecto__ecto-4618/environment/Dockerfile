FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Erlang and Elixir from Ubuntu packages
# Elixir requires ~> 1.14 according to mix.exs
RUN apt-get update && apt-get install -y \
    erlang \
    elixir \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/elixir-ecto/ecto.git src && \
    cd src && \
    (git fetch --depth 1 origin f43389655cd0f74e7a41609fb9823f9c7e94cb1b || git fetch --depth 1 origin "+refs/pull/4618/head:refs/remotes/origin/pr/4618") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Set environment variables for testing
ENV MIX_ENV=test
ENV FORCE_COLOR=1

# Install Hex (Elixir package manager) and Rebar (Erlang build tool)
RUN mix local.hex --force && \
    mix local.rebar --force

# Install project dependencies
RUN mix deps.get && \
    mix deps.compile

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly,
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Recompile after applying bug.patch
# Elixir is a compiled language (compiles to BEAM bytecode)
RUN mix deps.compile && mix compile

RUN rm -rf /app/src/.git

WORKDIR /app/src
