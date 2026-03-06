FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Foundry for running Solidity tests
RUN curl -L https://foundry.paradigm.xyz | bash && \
    /root/.foundry/bin/foundryup && \
    ln -s /root/.foundry/bin/forge /usr/local/bin/forge && \
    ln -s /root/.foundry/bin/cast /usr/local/bin/cast && \
    ln -s /root/.foundry/bin/anvil /usr/local/bin/anvil

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/simplex-chat/simplex-chat.git src && \
    cd src && \
    (git fetch --depth 1 origin 5eacc135d4329e79a2343978a7cb4829152b7de3 || git fetch --depth 1 origin "+refs/pull/6376/head:refs/remotes/origin/pr/6376") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly,
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

RUN rm -rf /app/src/.git

WORKDIR /app/src
