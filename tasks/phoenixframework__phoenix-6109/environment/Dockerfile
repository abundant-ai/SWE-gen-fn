FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js for JavaScript tests
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Install additional system packages for Erlang/Elixir
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    autoconf \
    libssl-dev \
    libncurses5-dev \
    m4 \
    && rm -rf /var/lib/apt/lists/*

# Install asdf version manager for Erlang and Elixir
RUN git clone https://github.com/asdf-vm/asdf.git /root/.asdf --branch v0.14.0 && \
    echo '. /root/.asdf/asdf.sh' >> /root/.bashrc

# Install Erlang and Elixir via asdf
ENV PATH="/root/.asdf/shims:/root/.asdf/bin:${PATH}"
RUN asdf plugin add erlang && \
    asdf plugin add elixir && \
    asdf install erlang 27.3 && \
    asdf install elixir 1.18.4-otp-27 && \
    asdf global erlang 27.3 && \
    asdf global elixir 1.18.4-otp-27

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/phoenixframework/phoenix.git src && \
    cd src && \
    (git fetch --depth 1 origin bf7714489b1646e144cb58da900adc5e8cf7e973 || git fetch --depth 1 origin "+refs/pull/6109/head:refs/remotes/origin/pr/6109") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Set environment variables for testing
ENV MIX_ENV=test
ENV PHX_CI=true

# Install Hex package manager and Rebar for Elixir
RUN mix local.hex --force && \
    mix local.rebar --force

# Install Mix dependencies for Elixir
RUN mix deps.get --only test

# Install dependencies for the installer sub-project
WORKDIR /app/src/installer
RUN mix deps.get --only test && mix compile

# Install dependencies for the integration_test sub-project
WORKDIR /app/src/integration_test
RUN mix deps.get --only test && mix compile

# Return to main project directory
WORKDIR /app/src

# Install Node.js dependencies for JavaScript tests
RUN npm ci

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly,
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Compile Elixir code after patching
RUN mix compile

# Recompile installer sub-project after patching
WORKDIR /app/src/installer
RUN mix compile

# Recompile integration_test sub-project after patching
WORKDIR /app/src/integration_test
RUN mix compile

WORKDIR /app/src

RUN rm -rf /app/src/.git

WORKDIR /app/src
