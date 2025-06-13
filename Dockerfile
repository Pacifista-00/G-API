# Multi-stage Dockerfile for a Rust application

# --- Stage 1: Build the application ---
# Use a Rust-specific image with tools for compilation.
# rust:1.77.2-slim-buster provides a good balance of features and size.
FROM rust:1.77.2-slim-buster AS builder

# Set the working directory inside the container
WORKDIR /app

# Install openssl-dev which is often a dependency for Rust crates
# This command updates apt package lists and installs necessary build tools and libraries.
RUN apt-get update && apt-get install -y openssl libssl-dev pkg-config

# Copy Cargo.toml and Cargo.lock to leverage Docker cache.
# If these files don't change, Docker can reuse the dependencies download layer.
COPY Cargo.toml Cargo.lock ./

# Create a dummy src/main.rs and build dependencies.
# This step helps cache dependencies. If source code changes but dependencies don't,
# Docker will reuse the dependency build.
RUN mkdir src/
RUN echo "fn main() {println!(\"hello\");}" > src/main.rs
RUN cargo build --release
# Remove the dummy src/main.rs
RUN rm -rf src

# Copy your actual source code into the container
COPY src ./src

# Build the release binary. --locked uses Cargo.lock to ensure reproducible builds.
# --target ensures we build for a generic Linux target.
# --target-dir specifies where to put the compiled binary within the builder stage.
RUN RUSTFLAGS="-C target-cpu=native" cargo build --release --locked --target-dir ./target

# --- Stage 2: Create a minimal runtime image ---
# Use a very small base image for the final application.
# debian:buster-slim is a good choice for production as it's small but includes glibc.
FROM debian:buster-slim

# Set the working directory for the final image
WORKDIR /app

# Copy the compiled binary from the builder stage into the final image
# `target/release/rust-api-render` is the path to your compiled binary inside the builder stage.
# `/usr/local/bin/rust-api-render` is where it will be placed in the final image.
COPY --from=builder /app/target/release/rust-api-render /usr/local/bin/rust-api-render

# Expose the port your application listens on.
# Render automatically injects the PORT environment variable, which our Rust code uses.
# We are changing EXPOSE 8000 to EXPOSE 3000 as the Rust code defaults to 3000 if PORT is not set.
# This will help Render's port scanner detect the service.
EXPOSE 3000

# Set the command to run when the container starts.
# This executes your compiled Rust binary.
CMD ["/usr/local/bin/rust-api-render"]