FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Haskell Stack (build tool) and dependencies
RUN apt-get update && apt-get install -y \
    wget \
    xz-utils \
    netbase \
    zlib1g-dev \
    libtinfo-dev \
    libgmp-dev \
    libffi-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Install Stack build tool manually (the installer script has issues with Ubuntu 24.04)
RUN wget -qO- https://github.com/commercialhaskell/stack/releases/download/v2.15.7/stack-2.15.7-linux-x86_64.tar.gz | tar xz --wildcards --strip-components=1 -C /usr/local/bin '*/stack'

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/commercialhaskell/stack.git src && \
    cd src && \
    (git fetch --depth 1 origin aa3eeca4d2e7a451434b25285f6d001e50907526 || git fetch --depth 1 origin "+refs/pull/6337/head:refs/remotes/origin/pr/6337") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Install GHC via Stack (downloads GHC 9.6.4)
RUN stack setup

# Build dependencies for the test suite only (not the main Stack executable)
# This is much faster than building the entire Stack project
# Enable integration-tests flag to include integration test dependencies
RUN stack build --only-dependencies --test --no-run-tests --flag stack:integration-tests

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Build the test suite with the buggy code
# Use --fast to skip optimizations, making the build much faster
# Enable integration-tests flag to include integration tests
RUN stack build --test --no-run-tests --fast --flag stack:integration-tests

RUN rm -rf /app/src/.git

WORKDIR /app/src
