FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install system packages and asdf dependencies
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    inotify-tools \
    unzip \
    autoconf \
    libssl-dev \
    libncurses5-dev \
    && rm -rf /var/lib/apt/lists/*

# Install asdf version manager
ENV ASDF_DIR=/opt/asdf
RUN git clone https://github.com/asdf-vm/asdf.git $ASDF_DIR --branch v0.14.0 && \
    echo '. /opt/asdf/asdf.sh' >> ~/.bashrc

# Install Erlang and Elixir via asdf
ENV PATH="${ASDF_DIR}/bin:${ASDF_DIR}/shims:${PATH}"
RUN . $ASDF_DIR/asdf.sh && \
    asdf plugin add erlang https://github.com/asdf-vm/asdf-erlang.git && \
    asdf plugin add elixir https://github.com/asdf-vm/asdf-elixir.git && \
    asdf install erlang 27.3 && \
    asdf install elixir 1.18.4-otp-27 && \
    asdf global erlang 27.3 && \
    asdf global elixir 1.18.4-otp-27

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/phoenixframework/phoenix_live_view.git src && \
    cd src && \
    (git fetch --depth 1 origin 7b8d4aee83d8e1219c294f3d978f2f76538730c5 || git fetch --depth 1 origin "+refs/pull/4125/head:refs/remotes/origin/pr/4125") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Set environment variable for test mode
ENV MIX_ENV=test

# Install Hex package manager and rebar (need to source asdf)
RUN . $ASDF_DIR/asdf.sh && \
    mix local.hex --force && \
    mix local.rebar --force

# Install Elixir dependencies
RUN . $ASDF_DIR/asdf.sh && mix deps.get

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly,
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Compile the Elixir project after patching
RUN . $ASDF_DIR/asdf.sh && mix compile

RUN rm -rf /app/src/.git

WORKDIR /app/src
