FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# OCaml is a self-hosted compiler - it needs an existing OCaml installation to build
# Install OCaml from apt (provides bootstrap compiler)
RUN apt-get update && apt-get install -y \
    ocaml \
    ocaml-native-compilers \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/ocaml/ocaml.git src && \
    cd src && \
    (git fetch --depth 1 origin d5420f818fd8e3b655dcea847c9db0f3221cf24b || git fetch --depth 1 origin "+refs/pull/14368/head:refs/remotes/origin/pr/14368") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Configure and build OCaml compiler from source
# Use minimal configuration to speed up build (disable optional components)
RUN ./configure \
    --disable-warn-error \
    --disable-ocamldoc \
    --disable-stdlib-manpages

# Build the OCaml compiler (both bytecode and native compilers)
# Also builds ocamltest which is needed to run the test suite
RUN make -j$(nproc)

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Rebuild OCaml after applying patch (compiled language)
# Clean build required when stdlib files are modified
RUN make clean && make -j$(nproc)

RUN rm -rf /app/src/.git

WORKDIR /app/src
