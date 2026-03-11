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
    (git fetch --depth 1 origin c7a5b8514ed902e309847a5e81dfc80cccae16f3 || git fetch --depth 1 origin "+refs/pull/1925/head:refs/remotes/origin/pr/1925") && \
    git checkout --detach FETCH_HEAD && \
    git submodule update --init --recursive

WORKDIR /app/src

# Set environment variables for Leiningen
ENV LEIN_ROOT=true

# Install dependencies using Leiningen
RUN lein deps

# If install/build steps touched tracked files, reset them so bug.patch applies cleanly,
RUN git reset --hard

# Apply bug.patch (includes submodule change)
COPY bug.patch /tmp/bug.patch
RUN patch -p1 --no-backup-if-mismatch < /tmp/bug.patch || true && \
    cd babashka.nrepl && git checkout 8428f44e77b8977769fc15cd427a2fee3ff8981b && cd .. && \
    rm /tmp/bug.patch

# Remove main .git but preserve submodule git directories for oracle agent
RUN find /app/src/.git -maxdepth 1 -mindepth 1 ! -name 'modules' -exec rm -rf {} + && \
    rm -f /app/src/.git/config /app/src/.git/HEAD /app/src/.git/index

WORKDIR /app/src
