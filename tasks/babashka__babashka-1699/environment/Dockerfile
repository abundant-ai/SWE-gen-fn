FROM ubuntu:24.04

# Base system packages (common to all languages)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    ca-certificates \
    patch \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Java
RUN apt-get update && apt-get install -y \
    openjdk-21-jdk \
    wget \
    && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# Install Clojure CLI tools
RUN curl -O https://download.clojure.org/install/linux-install-1.10.3.1040.sh && \
    chmod +x linux-install-1.10.3.1040.sh && \
    ./linux-install-1.10.3.1040.sh && \
    rm linux-install-1.10.3.1040.sh

# Install Leiningen
RUN wget https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein -O /usr/local/bin/lein && \
    chmod +x /usr/local/bin/lein && \
    lein version

WORKDIR /app

# Clone repo at HEAD commit (with fix applied)
RUN git clone https://github.com/babashka/babashka.git src && \
    cd src && \
    (git fetch --depth 1 origin 14e4dda82b282ef3a4cbdf2f26b3d52be9afcd90 || git fetch --depth 1 origin "+refs/pull/1699/head:refs/remotes/origin/pr/1699") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Set environment variables for Leiningen
ENV LEIN_ROOT=true

# Install dependencies using Leiningen
RUN lein deps

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly,
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
COPY bug.patch /tmp/bug.patch
RUN (patch -p1 < /tmp/bug.patch || true) && rm /tmp/bug.patch

# Reinstall dependencies with the buggy version (Clojure 1.11.2)
RUN lein deps

RUN rm -rf /app/src/.git

WORKDIR /app/src
