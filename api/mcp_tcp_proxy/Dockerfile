# Stage 1: Build the executables
FROM dart:stable AS builder

WORKDIR /app

# Copy necessary pubspec files first for dependency caching
# Copy main project pubspec (needed for todoist server potentially)
COPY pubspec.* /app/
# Copy proxy pubspec
COPY api/mcp_tcp_proxy/pubspec.yaml /app/api/mcp_tcp_proxy/pubspec.yaml
# Copy echo server pubspec (adjust path if it's different or doesn't exist)
# If mcp_echo_server doesn't have its own pubspec.yaml, remove this line.
COPY mcp_echo_server/pubspec.yaml /app/mcp_echo_server/pubspec.yaml

# Get dependencies for the main project (might be needed by todoist server)
# Run pub get in the root first
RUN dart pub get
# Get dependencies for the proxy
WORKDIR /app/api/mcp_tcp_proxy
RUN dart pub get
# Get dependencies for the echo server (if it has its own pubspec)
# If mcp_echo_server doesn't have its own pubspec.yaml, remove this WORKDIR and RUN block.
WORKDIR /app/mcp_echo_server
RUN dart pub get

# Copy the rest of the source code AFTER pub get for better caching
WORKDIR /app
COPY . .

# Create directory for compiled output
RUN mkdir /app/compiled_bin

# Compile the applications
# Ensure paths are correct relative to WORKDIR /app

# Compile TCP Proxy (Source: /app/bin/mcp_tcp_proxy.dart)
RUN dart compile exe bin/mcp_tcp_proxy.dart -o /app/compiled_bin/mcp_tcp_proxy_executable

# Compile Todoist Server (Source: /app/bin/todoist_mcp_server.dart)
# This needs access to /app/lib and /app/pubspec.lock from the main project copy
RUN dart compile exe bin/todoist_mcp_server.dart -o /app/compiled_bin/todoist_mcp_server_executable

# Compile Echo Server (Source: /app/mcp_echo_server/bin/mcp_echo_server.dart)
RUN dart compile exe mcp_echo_server/bin/mcp_echo_server.dart -o /app/compiled_bin/mcp_echo_server_executable


# Stage 2: Create the runtime image
FROM dart:stable AS runtime
# Consider using a smaller base like scratch if executables are fully self-contained
# FROM scratch AS runtime
# But dart:stable is safer if there are unexpected runtime dependencies

WORKDIR /app

# Copy only the compiled executables from the builder stage
COPY --from=builder /app/compiled_bin/ /app/bin/

# Make executables runnable
RUN chmod +x /app/bin/*

# Define the default port the proxy will listen on inside the container
ENV PROXY_PORT=8999
EXPOSE $PROXY_PORT

# Set the entrypoint to run the proxy executable
# The paths inside the container (/app/bin/...) are now correct
ENTRYPOINT ["/app/bin/mcp_tcp_proxy_executable", "--port", "$PROXY_PORT"]
