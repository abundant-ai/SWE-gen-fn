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
    (git fetch --depth 1 origin 4a992f154fa93f0a5222b2450a43649aee1958ef || git fetch --depth 1 origin "+refs/pull/1908/head:refs/remotes/origin/pr/1908") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Set environment variables for Leiningen
ENV LEIN_ROOT=true

# Install dependencies using Leiningen
RUN lein deps

# Reset tracked files so bug.patch applies cleanly
RUN git reset --hard

# Apply bug.patch to revert to buggy state (BASE)
# Note: Using --force to skip git submodule changes which can't be patched
COPY bug.patch /tmp/bug.patch
RUN patch -p1 --force --reject-file=- < /tmp/bug.patch || true && \
    rm /tmp/bug.patch

RUN rm -rf /app/src/.git

WORKDIR /app/src
