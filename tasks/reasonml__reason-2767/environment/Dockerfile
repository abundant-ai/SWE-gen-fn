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
    opam switch create 5.2.0 && \
    eval $(opam env)

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/reasonml/reason.git src && \
    cd src && \
    (git fetch --depth 1 origin 50a38cff511aea4ab6ef966e0ebbb179bc51bc8b || git fetch --depth 1 origin "+refs/pull/2767/head:refs/remotes/origin/pr/2767") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Set opam environment
ENV OPAM_SWITCH_PREFIX=/root/.opam/5.2.0
ENV PATH="/root/.opam/5.2.0/bin:${PATH}"

# Pin local directory and install dependencies (including dev dependencies)
# Pin ppxlib to version compatible with this older commit
# Pin menhir to avoid deprecated API issues
RUN opam pin add -n -y reason . && \
    opam install "ppxlib<0.36.0" -y && \
    opam install "menhir<20230608" -y && \
    opam install reason --deps-only --with-test -y && \
    opam install utop -y

# If install steps touched tracked files, reset them so bug.patch applies cleanly
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN git apply /tmp/bug.patch && rm /tmp/bug.patch

RUN rm -rf /app/src/.git

WORKDIR /app/src
