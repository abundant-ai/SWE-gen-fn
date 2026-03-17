FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install dependencies for building Erlang from source
RUN apt-get update && apt-get install -y \
    autoconf \
    m4 \
    libncurses5-dev \
    libssl-dev \
    wget \
    unzip \
    gpg \
    && rm -rf /var/lib/apt/lists/*

# Install asdf version manager
ENV ASDF_DIR=/root/.asdf
RUN git clone https://github.com/asdf-vm/asdf.git ${ASDF_DIR} --branch v0.14.1 && \
    echo '. ${ASDF_DIR}/asdf.sh' >> ~/.bashrc

# Install Erlang and Elixir using asdf (matching CI: Elixir 1.17.2, OTP 27)
RUN . ${ASDF_DIR}/asdf.sh && \
    asdf plugin add erlang && \
    asdf plugin add elixir && \
    asdf install erlang 27.0.1 && \
    asdf install elixir 1.17.2-otp-27 && \
    asdf global erlang 27.0.1 && \
    asdf global elixir 1.17.2-otp-27

ENV PATH="${ASDF_DIR}/shims:${ASDF_DIR}/bin:${PATH}"

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/elixir-ecto/ecto.git src && \
    cd src && \
    (git fetch --depth 1 origin 6159829f8f612d372e34490fb8c2cdc9aed20360 || git fetch --depth 1 origin "+refs/pull/4335/head:refs/remotes/origin/pr/4335") && \
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
# Need to re-fetch dependencies since mix.lock was modified by the patch
RUN mix deps.get && mix deps.compile && mix compile

RUN rm -rf /app/src/.git

WORKDIR /app/src
