FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install OCaml and opam (OCaml package manager)
RUN apt-get update && apt-get install -y \
    opam \
    m4 \
    unzip \
    rsync \
    bubblewrap \
    strace \
    && rm -rf /var/lib/apt/lists/*

# Initialize opam and install OCaml 4.14.x (as per CI configuration)
RUN opam init --disable-sandboxing --bare -y && \
    opam switch create 4.14.1 4.14.1 && \
    eval $(opam env)

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/ocaml/dune.git src && \
    cd src && \
    (git fetch --depth 1 origin 2a89e20c5c6f9d8cb0289171dc7a99dcf0131e3c || git fetch --depth 1 origin "+refs/pull/9140/head:refs/remotes/origin/pr/9140") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Set up opam environment
ENV OPAM_SWITCH_PREFIX=/root/.opam/4.14.1
ENV PATH="/root/.opam/4.14.1/bin:${PATH}"

# Configure git user for tests that require it
RUN git config --global user.name "github-actions[bot]" && \
    git config --global user.email "github-actions[bot]@users.noreply.github.com"

# Install dune from opam (latest version that supports lang dune 3.21)
RUN opam install -y dune ppx_expect ppx_inline_test

# Bootstrap dune from source (our version under test)
RUN opam exec -- ocaml boot/bootstrap.ml

# Build dune from source
RUN opam exec -- ./_boot/dune.exe build dune.install --release --profile dune-bootstrap

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly,
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Rebuild dune after applying bug.patch
RUN opam exec -- ocaml boot/bootstrap.ml && \
    opam exec -- ./_boot/dune.exe build dune.install --release --profile dune-bootstrap

RUN rm -rf /app/src/.git

WORKDIR /app/src
