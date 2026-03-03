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

# Install ghcup, GHC 9.2.5, and cabal
# Using GHC 9.2.5 to match the CI configuration at this commit
RUN curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | \
    BOOTSTRAP_HASKELL_NONINTERACTIVE=1 \
    BOOTSTRAP_HASKELL_MINIMAL=1 \
    BOOTSTRAP_HASKELL_ADJUST_BASHRC=no \
    sh && \
    /root/.ghcup/bin/ghcup install ghc 9.2.5 && \
    /root/.ghcup/bin/ghcup set ghc 9.2.5 && \
    /root/.ghcup/bin/ghcup install cabal latest && \
    /root/.ghcup/bin/ghcup set cabal latest

ENV PATH="/root/.ghcup/bin:${PATH}"

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/hadolint/hadolint.git src && \
    cd src && \
    (git fetch --depth 1 origin 45afba856e5fa2c377806318f44f19af17b133f2 || git fetch --depth 1 origin "+refs/pull/871/head:refs/remotes/origin/pr/871") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Update Cabal package index
RUN cabal update

# Configure with minimal options for faster builds
RUN cabal configure --enable-tests --disable-optimization

# Install dependencies including test dependencies
RUN cabal build all --only-dependencies -j$(nproc)

# Install hspec-discover explicitly for test discovery
RUN cabal install hspec-discover

# Add cabal bin to PATH so hspec-discover can be found
ENV PATH="/root/.local/bin:${PATH}"

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly,
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# Rebuild after applying patch (Haskell is a compiled language) - parallel build
RUN cabal build all -j$(nproc)

RUN rm -rf /app/src/.git

WORKDIR /app/src
