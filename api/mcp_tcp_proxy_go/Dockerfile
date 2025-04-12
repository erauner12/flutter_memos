# Stage 1: Compile Dart stdio servers for Linux (Isolated)
FROM dart:stable AS dart-builder

# Create a common output directory early
RUN mkdir /output

WORKDIR /build

# Install certs and explicitly update the store
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates && \
    update-ca-certificates --fresh && \
    rm -rf /var/lib/apt/lists/*

# --- Build Todoist Server ---
WORKDIR /build/todoist_server

# Create the structure expected by the dependency override and source layout
# Ensure target directories exist before copying into them
RUN mkdir -p bin packages/flutter_memos/lib/services packages/flutter_memos/lib/todoist_api

# Copy the minimal pubspec (WITH dependency override)
# Path relative to context root: bin/todoist_mcp_server.pubspec.yaml
COPY bin/todoist_mcp_server.pubspec.yaml ./pubspec.yaml

# Copy the main server executable source
# Path relative to context root: bin/todoist_mcp_server.dart
COPY bin/todoist_mcp_server.dart ./bin/

# Copy the necessary library files into the overridden package structure
# These paths are relative to the build context root
COPY lib/services/todoist_api_service.dart ./packages/flutter_memos/lib/services/
COPY lib/todoist_api ./packages/flutter_memos/lib/todoist_api/

# Create a dummy pubspec.yaml for the overridden package to satisfy the path dependency
RUN echo "name: flutter_memos\ndescription: Minimal pubspec for build override.\nenvironment:\n  sdk: '>=3.0.0 <4.0.0'" > ./packages/flutter_memos/pubspec.yaml

# Get dependencies for Todoist server ONLY (should now resolve the path override)
# This generates .dart_tool/package_config.json mapping flutter_memos to ./packages/flutter_memos
RUN dart pub get --verbose

# Compile Todoist Server - Explicitly use the generated package config
RUN dart compile exe bin/todoist_mcp_server.dart \
    --packages=.dart_tool/package_config.json \
    -o /output/todoist_mcp_server_executable


# --- Build Echo Server ---
WORKDIR /build/echo_server
# Create necessary directories
RUN mkdir -p bin
# Copy minimal pubspec for echo server (relative to context root)
COPY mcp_echo_server/bin/mcp_echo_server.pubspec.yaml ./pubspec.yaml
# Copy source code needed by echo server (relative to context root)
COPY mcp_echo_server/bin/mcp_echo_server.dart ./bin/

# Get dependencies for Echo server ONLY
# This generates .dart_tool/package_config.json
RUN dart pub get --verbose
# Compile Echo Server - Explicitly use the generated package config
RUN dart compile exe bin/mcp_echo_server.dart \
    --packages=.dart_tool/package_config.json \
    -o /output/mcp_echo_server_executable


# Stage 2: Build the Go proxy executable
FROM golang:1.22-alpine AS go-builder

WORKDIR /src

# Install ca-certificates, might be needed by Go for HTTPS calls during build
RUN apk update && apk add --no-cache ca-certificates git

# Copy Go module files relative to the build context (project root)
COPY api/mcp_tcp_proxy_go/go.mod api/mcp_tcp_proxy_go/go.sum* ./
RUN go mod download

# Copy the Go source code relative to the build context
COPY api/mcp_tcp_proxy_go/. .

# Create output directory
RUN mkdir /output

# Build the Go application statically for Alpine (still okay as Go build is static)
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /output/mcp_tcp_proxy_executable ./main.go


# Stage 3: Create the minimal runtime image (Debian-based for Dart compatibility)
FROM debian:stable-slim

WORKDIR /app

# Install ca-certificates needed for potential HTTPS calls from Go/Dart runtime
# Also install bash, as some Dart executables might implicitly rely on it (using apt-get)
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates bash && \
    rm -rf /var/lib/apt/lists/*

# Create a non-root user for security (adduser command works on Debian)
RUN addgroup --system appgroup && adduser --system --ingroup appgroup appuser

# Create the bin directory for Dart executables
RUN mkdir /app/bin

# Copy the compiled Go proxy executable from the go-builder stage
COPY --from=go-builder /output/mcp_tcp_proxy_executable /app/
# Copy the compiled Dart stdio server executables from the dart-builder stage
COPY --from=dart-builder /output/ /app/bin/

# Ensure all executables are runnable by the appuser
RUN chown -R appuser:appgroup /app && \
    chmod +x /app/mcp_tcp_proxy_executable && \
    chmod +x /app/bin/*

# Define the default port
ENV PROXY_PORT=8999
EXPOSE $PROXY_PORT

# Add app directories to PATH for the appuser
ENV PATH="/app:/app/bin:${PATH}"

# Switch to the non-root user
USER appuser

# Set the entrypoint using the reliable /bin/sh -c method for variable expansion
ENTRYPOINT ["/bin/sh", "-c", "/app/mcp_tcp_proxy_executable --port $PROXY_PORT"]
