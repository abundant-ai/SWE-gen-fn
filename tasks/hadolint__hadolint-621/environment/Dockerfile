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

# Install ghcup, GHC 8.10, and cabal
# Using GHC 8.10 to match the CI configuration at this commit
RUN curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | \
    BOOTSTRAP_HASKELL_NONINTERACTIVE=1 \
    BOOTSTRAP_HASKELL_MINIMAL=1 \
    BOOTSTRAP_HASKELL_ADJUST_BASHRC=no \
    sh && \
    /root/.ghcup/bin/ghcup install ghc 8.10 && \
    /root/.ghcup/bin/ghcup set ghc 8.10 && \
    /root/.ghcup/bin/ghcup install cabal latest && \
    /root/.ghcup/bin/ghcup set cabal latest

ENV PATH="/root/.ghcup/bin:${PATH}"

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/hadolint/hadolint.git src && \
    cd src && \
    (git fetch --depth 1 origin 883d6e6b9b51dd90b0ef5c9e0d52b1825045e761 || git fetch --depth 1 origin "+refs/pull/621/head:refs/remotes/origin/pr/621") && \
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

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

RUN rm -rf /app/src/.git

WORKDIR /app/src
