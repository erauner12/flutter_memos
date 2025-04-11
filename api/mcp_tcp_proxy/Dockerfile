# Stage 1: Build the executables using the standard Dart SDK image
FROM dart:stable AS builder

WORKDIR /app

# Install necessary packages like ca-certificates if needed for network requests during build (unlikely here)
# RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

# Create a non-root user and group
RUN groupadd -r appgroup && useradd --no-log-init -m -r -g appgroup appuser

# Copy pubspec files first
COPY pubspec.* ./
# Copy source code for the main project (needed for dependencies of stdio servers)
COPY bin ./bin
COPY lib ./lib
# Copy source code for the echo server
COPY mcp_echo_server ./mcp_echo_server
# Copy source code for the proxy itself
COPY api/mcp_tcp_proxy ./api/mcp_tcp_proxy

# Set ownership for the entire app directory *before* pub get
RUN chown -R appuser:appgroup /app

# Switch to the non-root user
USER appuser

# --- Build Dependencies ---
# Get dependencies for the main project (needed for todoist server)
RUN dart pub get

# Get dependencies for the proxy (if it has its own pubspec.yaml)
# If the proxy pubspec is at api/mcp_tcp_proxy/pubspec.yaml:
WORKDIR /app/api/mcp_tcp_proxy
RUN dart pub get
WORKDIR /app # Switch back to the main app directory

# --- Compile Executables ---
# Create directory for compiled output
RUN mkdir -p /app/compiled_bin

# Compile TCP Proxy
# Ensure the path to the main Dart file is correct relative to WORKDIR /app
RUN dart compile exe api/mcp_tcp_proxy/bin/mcp_tcp_proxy.dart -o /app/compiled_bin/mcp_tcp_proxy_executable

# Compile Todoist Server
RUN dart compile exe bin/todoist_mcp_server.dart -o /app/compiled_bin/todoist_mcp_server_executable

# Compile Echo Server
RUN dart compile exe mcp_echo_server/bin/mcp_echo_server.dart -o /app/compiled_bin/mcp_echo_server_executable


# Stage 2: Create the runtime image
# Use the same base image or a minimal one like dart:stable-slim
FROM dart:stable AS runtime
# FROM dart:stable-slim AS runtime # Consider slim for smaller size

WORKDIR /app

# Create the same non-root user and group in the runtime stage
RUN groupadd -r appgroup && useradd --no-log-init -m -r -g appgroup appuser

# Copy only the compiled executables from the builder stage, setting ownership
COPY --from=builder --chown=appuser:appgroup /app/compiled_bin/ /app/bin/

# Make executables runnable (permissions should be preserved, but explicit chmod is safe)
RUN chmod +x /app/bin/*

# Define the default port the proxy will listen on inside the container
ENV PROXY_PORT=8999
EXPOSE $PROXY_PORT

# Switch to the non-root user for running the application
USER appuser

# Set the entrypoint to run the proxy executable (as appuser)
# The paths inside the container (/app/bin/...) are now correct
ENTRYPOINT ["/app/bin/mcp_tcp_proxy_executable", "--port", "$PROXY_PORT"]
