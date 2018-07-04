FROM windoze/musl-cross-make

ARG TOOLCHAIN=stable

RUN useradd rust --user-group --create-home --shell /bin/bash --groups sudo
ADD sudoers /etc/sudoers.d/nopasswd
USER rust
RUN mkdir -p /home/rust/libs /home/rust/src
ENV PATH=/home/rust/.cargo/bin:/opt/cross/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Install rust and musl target
RUN curl https://sh.rustup.rs -sSf | \
    sh -s -- -y --default-toolchain $TOOLCHAIN && \
    rustup target add x86_64-unknown-linux-musl
# HACK: Custom linker wrapper for cargo/rustc with C++ deps
ADD cargo-g++ /opt/cross/bin
# HACK: Bindgen needs to be using GNU target instead of musl, otherwise it cannot load system libclang.so
# We install here before setting default target to musl
RUN sudo chmod +x /opt/cross/bin/cargo-g++ && \
    cargo install bindgen
# Set cargo default target and parameters
ADD cargo-config.toml /home/rust/.cargo/config

RUN export USER=rust &&  cd /tmp && rm -rf t && \
    cargo new --bin t && \
    cd t && \
    echo 'void = "*"' >> Cargo.toml && \
    cat Cargo.toml && \
    cargo build && \
    cd /tmp && rm -rf t

WORKDIR /home/rust/src

