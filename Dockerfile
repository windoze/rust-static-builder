FROM ubuntu:18.04

ARG TOOLCHAIN=stable

# Baseline
RUN apt-get update && \
    apt-get install -y build-essential git cmake sudo curl file wget protobuf-compiler-grpc ca-certificates && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    useradd rust --user-group --create-home --shell /bin/bash --groups sudo
ADD sudoers /etc/sudoers.d/nopasswd
USER rust
RUN mkdir -p /home/rust/libs /home/rust/src
ENV PATH=/home/rust/.cargo/bin:/opt/cross/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Install cross compiling toolchain for musl
RUN cd /home/rust && \
    git clone https://github.com/richfelker/musl-cross-make.git 
ADD config.mak /home/rust/musl-cross-make
RUN cd /home/rust/musl-cross-make && \
    make -j 4 && \
    sudo make install && \
    cd .. && \
    rm -rf musl-cross-make
# I'm tired to checkout whole LLVM source to build it
ADD libunwind.a /opt/cross/x86_64-linux-musl/lib
ENV CC=/opt/cross/bin/x86_64-linux-musl-gcc
ENV CXX=/opt/cross/bin/x86_64-linux-musl-g++

# Install rust and musl target
RUN curl https://sh.rustup.rs -sSf | \
    sh -s -- -y --default-toolchain $TOOLCHAIN && \
    rustup target add x86_64-unknown-linux-musl && \
    cargo install rustfmt
# HACK: Custom linker wrapper for cargo/rustc with C++ deps
ADD cargo-g++ /opt/cross/bin
RUN sudo chmod +x /opt/cross/bin/cargo-g++
# Set cargo default target and parameters
ADD cargo-config.toml /home/rust/.cargo/config

RUN echo "Building OpenSSL" && \
    cd /tmp && \
    OPENSSL_VERSION=1.0.2o && \
    curl -LO "https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz" && \
    tar xvzf "openssl-$OPENSSL_VERSION.tar.gz" && cd "openssl-$OPENSSL_VERSION" && \
    ./Configure no-shared no-zlib -fPIC --prefix=/opt/cross/x86_64-linux-musl linux-x86_64 && \
    env C_INCLUDE_PATH=/opt/cross/x86_64-linux-musl/include/ make depend && \
    make && sudo make install && \
    \
    echo "Building zlib" && \
    cd /tmp && \
    ZLIB_VERSION=1.2.11 && \
    curl -LO "http://zlib.net/zlib-$ZLIB_VERSION.tar.gz" && \
    tar xzf "zlib-$ZLIB_VERSION.tar.gz" && cd "zlib-$ZLIB_VERSION" && \
    ./configure --static --prefix=/opt/cross/x86_64-linux-musl && \
    make && sudo make install && \
    \
    rm -r /tmp/*

ENV OPENSSL_DIR=/opt/cross/x86_64-linux-musl \
    OPENSSL_INCLUDE_DIR=/opt/cross/x86_64-linux-musl/include/ \
    DEP_OPENSSL_INCLUDE=/opt/cross/x86_64-linux-musl/include/ \
    OPENSSL_LIB_DIR=/opt/cross/x86_64-linux-musl/lib/ \
    OPENSSL_STATIC=1 \
    LIBZ_SYS_STATIC=1 \
    TARGET=musl

WORKDIR /home/rust/src

