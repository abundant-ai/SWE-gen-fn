FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# This is a Haskell project (PostgREST), but we only need Python to verify source code changes
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

RUN curl -LsSf https://astral.sh/uv/install.sh | sh && mv /root/.local/bin/uv /usr/local/bin/uv

WORKDIR /app

RUN git clone https://github.com/PostgREST/postgrest.git src && \
    cd src && \
    (git fetch --depth 1 origin b5ea4bedd14fcbee4556d00073ab39b06f3519ec || git fetch --depth 1 origin "+refs/pull/4323/head:refs/remotes/origin/pr/4323") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

RUN uv venv /opt/venv
RUN uv pip install --python /opt/venv/bin/python pytest pytest-xdist requests pyyaml syrupy pyjwt requests-unixsocket

ENV PATH="/opt/venv/bin:${PATH}"

RUN git reset --hard

COPY bug.patch /tmp/bug.patch
RUN patch -p1 < /tmp/bug.patch && rm /tmp/bug.patch

RUN rm -rf /app/src/.git

WORKDIR /app/src
