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
    (git fetch --depth 1 origin 6512572a44c3bccbf8cc77901a7452b35bc5e9d5 || git fetch --depth 1 origin "+refs/pull/8333/head:refs/remotes/origin/pr/8333") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Set up opam environment
ENV OPAM_SWITCH_PREFIX=/root/.opam/4.14.1
ENV PATH="/root/.opam/4.14.1/bin:${PATH}"

# Configure git user for tests that require it
RUN git config --global user.name "github-actions[bot]" && \
    git config --global user.email "github-actions[bot]@users.noreply.github.com"

# Install dune, ppx packages, menhir, coq, and additional dependencies for testing
RUN opam install -y "dune<3.12" "ppx_expect<v0.16" "ppx_inline_test<v0.16" "menhir" "coq>=8.14" "result>=1.5" "lwt>=5.3.0"

# Bootstrap dune from source (our version under test)
RUN opam exec -- ocaml boot/bootstrap.ml

# Build dune from source
RUN opam exec -- ./_boot/dune.exe build dune.install --release --profile dune-bootstrap

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Note: Not rebuilding after bug.patch because the buggy state doesn't compile.
# The test will rebuild after applying the fix (Oracle agent) or test file only (NOP agent).

RUN rm -rf /app/src/.git

WORKDIR /app/src
