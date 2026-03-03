FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install OCaml and dependencies
RUN apt-get update && apt-get install -y \
    opam \
    m4 \
    rsync \
    && rm -rf /var/lib/apt/lists/*

# Initialize opam and install OCaml
RUN opam init -y --disable-sandboxing --bare && \
    opam switch create 4.14.0 && \
    eval $(opam env)

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/reasonml/reason.git src && \
    cd src && \
    (git fetch --depth 1 origin 62cd2a6c93b84515435baaea24268dfbd6849ece || git fetch --depth 1 origin "+refs/pull/2684/head:refs/remotes/origin/pr/2684") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Set opam environment
ENV OPAM_SWITCH_PREFIX=/root/.opam/4.14.0
ENV PATH="/root/.opam/4.14.0/bin:${PATH}"

# Pin local directory and install dependencies (including dev dependencies)
# Pin ppxlib to a compatible version (< 0.32.0 to avoid Pexp_fun API changes)
# Pin menhir to avoid Lr1.reductions deprecation warnings (introduced in later versions)
RUN opam pin add -n -y reason . && \
    opam pin add ppxlib 0.28.0 -y && \
    opam pin add menhir 20220210 -y && \
    opam install reason --deps-only --with-test -y && \
    opam install utop -y

# If install steps touched tracked files, reset them so bug.patch applies cleanly
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

RUN rm -rf /app/src/.git

WORKDIR /app/src
