FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Erlang/OTP 26+ by downloading and installing the Erlang Solutions package
RUN curl -fsSLO https://binaries2.erlang-solutions.com/ubuntu/pool/contrib/e/esl-erlang/esl-erlang_27.3-1~ubuntu~noble_amd64.deb && \
    apt-get update && apt-get install -y ./esl-erlang_27.3-1~ubuntu~noble_amd64.deb && \
    rm esl-erlang_27.3-1~ubuntu~noble_amd64.deb && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/elixir-lang/elixir.git src && \
    cd src && \
    (git fetch --depth 1 origin cdd69909109ceafd994dd334981b2f2fa58a6c0f || git fetch --depth 1 origin "+refs/pull/15026/head:refs/remotes/origin/pr/15026") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Set environment variables for Elixir compilation and testing
ENV ELIXIR_ASSERT_TIMEOUT=2000
ENV ELIXIRC_OPTS="--warnings-as-errors"
ENV LANG=C.UTF-8

# Compile Elixir from source
RUN make compile

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch

# Clean and rebuild Elixir after applying bug.patch without type inference
# The buggy map implementation breaks type inference, so we must disable it
RUN make clean && \
    ERL="/usr/bin/erl" make compile ELIXIRC_OPTS="-e 'Code.put_compiler_option :infer_signatures, []'"

RUN rm -rf /app/src/.git

WORKDIR /app/src
