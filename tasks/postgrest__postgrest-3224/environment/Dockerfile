FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/PostgREST/postgrest.git src && \
    cd src && \
    (git fetch --depth 1 origin 00fbe9ff3e54cdfab2a3cb4489bf3095e19dd056 || git fetch --depth 1 origin "+refs/pull/3224/head:refs/remotes/origin/pr/3224") && \
    git checkout --detach FETCH_HEAD && \
    (git submodule update --init --recursive || true)

WORKDIR /app/src

ENV CI=true

RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

RUN rm -rf /app/src/.git

WORKDIR /app/src
