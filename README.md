# Docker image to build statically linked Rust applications.

Usage:
```
docker run -it --rm -v "$(pwd)":/home/rust/src -v $HOME/.cargo/git:/home/rust/.cargo/git -v $HOME/.cargo/registry:/home/rust/.cargo/registry windoze/rust-static-builder cargo build --release
```

Or you can add an alias like:
```
alias rsb='docker run -it --rm -v "$(pwd)":/home/rust/src -v $HOME/.cargo/git:/home/rust/.cargo/git -v $HOME/.cargo/registry:/home/rust/.cargo/registry windoze/rust-static-builder'
```
Then run `rsb cargo build ...` under the root directory of the cargo project.

Output binary is located under `path_to_project/target/x86_64-unknown-linux-musl/{debug,release}`.

# WARNING:

**Output binary is statically linked with libstdc++, which uses GPLv3 license with an exception, consult your lawyer before distributing your application.**
