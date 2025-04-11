# Stage 1: Build the executables
# FROM dart:stable AS builder
FROM cirrusci/flutter:3.19.6 AS builder

WORKDIR /app

# Set frontend to noninteractive to avoid tzdata prompts
ENV DEBIAN_FRONTEND=noninteractive

# Update package lists, install/update certificates, force update, and clean up
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates curl dnsutils tzdata && \
    update-ca-certificates --fresh && \
    rm -rf /var/lib/apt/lists/*

# Create a non-root user and group
RUN groupadd -r appgroup && useradd --no-log-init -r -g appgroup appuser

# Create and set permissions for pub cache directory
RUN mkdir /home/appuser/.pub-cache && chown -R appuser:appgroup /home/appuser/.pub-cache
ENV PUB_CACHE=/home/appuser/.pub-cache

# Switch to the non-root user BEFORE copying files and running pub get/compile
USER appuser

# Copy ALL source code first (respecting .dockerignore)
# Files will be owned by appuser now
COPY --chown=appuser:appgroup . .

# Test network connectivity before attempting pub get
RUN echo "--- Testing Network Connectivity ---" && \
    curl -4s --head https://pub.dev || echo "Failed to reach pub.dev via curl (IPv4)" && \
    nslookup pub.dev || echo "Failed nslookup for pub.dev" && \
    ping -c 3 pub.dev || echo "Failed to ping pub.dev" && \
    echo "--- Network Test Complete ---"

# Run pub get ONCE from the root directory using flutter (as appuser).
# RUN dart pub get
RUN flutter pub get

# Create directory for compiled output (owned by appuser)
RUN mkdir /app/compiled_bin

# Compile the applications (will run as appuser)
# Ensure paths are correct relative to WORKDIR /app

# Compile TCP Proxy (Source: /app/api/mcp_tcp_proxy/bin/mcp_tcp_proxy.dart - uses /app/api/mcp_tcp_proxy/pubspec.yaml)
RUN dart compile exe api/mcp_tcp_proxy/bin/mcp_tcp_proxy.dart -o /app/compiled_bin/mcp_tcp_proxy_executable

# Compile Todoist Server (Source: /app/bin/todoist_mcp_server.dart - uses /app/pubspec.yaml)
RUN dart compile exe bin/todoist_mcp_server.dart -o /app/compiled_bin/todoist_mcp_server_executable

# Compile Echo Server (Source: /app/mcp_echo_server/bin/mcp_echo_server.dart - uses /app/pubspec.yaml)
RUN dart compile exe mcp_echo_server/bin/mcp_echo_server.dart -o /app/compiled_bin/mcp_echo_server_executable

# Stage 2: Create the runtime image
# Use the same base image or a minimal one like dart:stable-slim
FROM dart:stable AS runtime
# FROM dart:stable-slim AS runtime # Consider slim for smaller size

WORKDIR /app

# Create the same non-root user and group in the runtime stage
RUN groupadd -r appgroup && useradd --no-log-init -r -g appgroup appuser

# Copy only the compiled executables from the builder stage, setting ownership
COPY --from=builder --chown=appuser:appgroup /app/compiled_bin/ /app/bin/

# Make executables runnable (already owned by appuser)
# RUN chmod +x /app/bin/* # chmod might not be needed if permissions are correct from COPY

# Define the default port the proxy will listen on inside the container
ENV PROXY_PORT=8999
EXPOSE $PROXY_PORT

# Switch to the non-root user for running the application
USER appuser

# Set the entrypoint to run the proxy executable (as appuser)
# The paths inside the container (/app/bin/...) are now correct
ENTRYPOINT ["/app/bin/mcp_tcp_proxy_executable", "--port", "$PROXY_PORT"]
