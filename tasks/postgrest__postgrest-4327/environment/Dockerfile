FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# This is a Haskell project (PostgREST), but we only need Python to run IO tests
# The tests verify code behavior changes without needing to build PostgREST
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Install uv for fast Python package management
RUN curl -LsSf https://astral.sh/uv/install.sh | sh && mv /root/.local/bin/uv /usr/local/bin/uv

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/PostgREST/postgrest.git src && \
    cd src && \
    (git fetch --depth 1 origin dfce438c886e87fc5793a30b3212dee53bf6f684 || git fetch --depth 1 origin "+refs/pull/4327/head:refs/remotes/origin/pr/4327") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Create venv and install Python test dependencies
RUN uv venv /opt/venv
RUN uv pip install --python /opt/venv/bin/python pytest pytest-xdist requests pyyaml syrupy pyjwt requests-unixsocket

ENV PATH="/opt/venv/bin:${PATH}"

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly,
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

# No rebuild needed - Python tests don't require compilation

RUN rm -rf /app/src/.git

WORKDIR /app/src
