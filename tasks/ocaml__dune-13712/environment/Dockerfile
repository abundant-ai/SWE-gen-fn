FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Install OCaml and opam (OCaml package manager)
RUN apt-get update && apt-get install -y \
    opam \
    m4 \
    unzip \
    rsync \
    bubblewrap \
    strace \
    libgmp-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Initialize opam and install OCaml 4.14.x (as per CI configuration)
RUN opam init --disable-sandboxing --bare -y && \
    opam switch create 4.14.1 4.14.1 && \
    eval $(opam env)

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/ocaml/dune.git src && \
    cd src && \
    (git fetch --depth 1 origin e1bd4e2bea628328b599d9b8c2064aeb45d45c04 || git fetch --depth 1 origin "+refs/pull/13712/head:refs/remotes/origin/pr/13712") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Set up opam environment
ENV OPAM_SWITCH_PREFIX=/root/.opam/4.14.1
ENV PATH="/root/.opam/4.14.1/bin:${PATH}"

# Configure git user for tests that require it
RUN git config --global user.name "github-actions[bot]" && \
    git config --global user.email "github-actions[bot]@users.noreply.github.com"

# Install dune dependencies and test packages
# Core dependencies based on opam/dune.opam with-dev-setup section
RUN opam install -y \
    lwt \
    csexp \
    menhir \
    ppx_expect \
    spawn \
    ppx_inline_test \
    ctypes \
    uutf \
    pp

# Bootstrap dune from source (our version under test)
RUN opam exec -- ocaml boot/bootstrap.ml

# Build dune from source
RUN opam exec -- ./_boot/dune.exe build dune.install --release --profile dune-bootstrap

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly,
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Note: Not rebuilding after bug.patch because the buggy state doesn't compile.
# The test will rebuild after applying the fix (Oracle agent) or test file only (NOP agent).

RUN rm -rf /app/src/.git

WORKDIR /app/src
