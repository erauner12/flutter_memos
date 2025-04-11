# Stage 1: Build the executables
FROM dart:stable AS builder

WORKDIR /app

# Update certificate authorities first to prevent TLS errors during pub get
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates && rm -rf /var/lib/apt/lists/*

# Copy ALL source code first
COPY . .

# Run pub get ONCE from the root directory.
# This should resolve dependencies for the main project, the proxy,
# the echo server, and the todoist server based on their pubspecs.
RUN dart pub get

# Create directory for compiled output
RUN mkdir /app/compiled_bin

# Compile the applications
# Ensure paths are correct relative to WORKDIR /app

# Compile TCP Proxy (Source: /app/api/mcp_tcp_proxy/bin/mcp_tcp_proxy.dart - uses /app/api/mcp_tcp_proxy/pubspec.yaml)
# Note: The WORKDIR is /app, so paths are relative to that.
RUN dart compile exe api/mcp_tcp_proxy/bin/mcp_tcp_proxy.dart -o /app/compiled_bin/mcp_tcp_proxy_executable

# Compile Todoist Server (Source: /app/bin/todoist_mcp_server.dart - uses /app/pubspec.yaml)
RUN dart compile exe bin/todoist_mcp_server.dart -o /app/compiled_bin/todoist_mcp_server_executable

# Compile Echo Server (Source: /app/mcp_echo_server/bin/mcp_echo_server.dart - uses /app/pubspec.yaml)
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
