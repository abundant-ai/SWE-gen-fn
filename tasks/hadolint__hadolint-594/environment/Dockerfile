FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Haskell dependencies
RUN apt-get update && apt-get install -y \
    libgmp-dev \
    libffi-dev \
    libncurses-dev \
    libtinfo-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Stack (Haskell build tool)
# Stack will manage GHC and dependencies according to stack.yaml
RUN curl -sSL https://get.haskellstack.org/ | sh

ENV PATH="/root/.local/bin:${PATH}"

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/hadolint/hadolint.git src && \
    cd src && \
    (git fetch --depth 1 origin 313bdad23fa7b0e64a4e3df60a08b32e3621b712 || git fetch --depth 1 origin "+refs/pull/594/head:refs/remotes/origin/pr/594") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Build project with Stack (installs GHC, dependencies, and builds tests)
# Using --no-run-tests to only build, not run tests yet
RUN stack build --test --no-run-tests --fast -j$(nproc)

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

RUN rm -rf /app/src/.git

WORKDIR /app/src
