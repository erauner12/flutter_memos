# Stage 1: Compile Dart stdio servers for Linux (Isolated)
FROM dart:stable AS dart-builder

# Create a common output directory early
RUN mkdir /output

WORKDIR /build

# Install certs just in case
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates && rm -rf /var/lib/apt/lists/*

# --- Build Todoist Server ---
WORKDIR /build/todoist_server

# Create the structure expected by the dependency override and source layout
# Ensure target directories exist before copying into them
RUN mkdir -p bin packages/flutter_memos/lib/services packages/flutter_memos/lib/todoist_api

# Copy the modified minimal pubspec (with dependency override)
# This pubspec should be located at bin/todoist_mcp_server.pubspec.yaml in the build context
COPY bin/todoist_mcp_server.pubspec.yaml ./pubspec.yaml

# Copy the main server executable source
# This should be located at bin/todoist_mcp_server.dart in the build context
COPY bin/todoist_mcp_server.dart ./bin/

# Copy the necessary library files into the overridden package structure
# These paths are relative to the build context root
COPY lib/services/todoist_api_service.dart ./packages/flutter_memos/lib/services/
COPY lib/todoist_api ./packages/flutter_memos/lib/todoist_api/

# Get dependencies for Todoist server ONLY (should use the override)
RUN dart pub get --verbose

# Compile Todoist Server
RUN dart compile exe bin/todoist_mcp_server.dart -o /output/todoist_mcp_server_executable


# --- Build Echo Server ---
WORKDIR /build/echo_server
# Create necessary directories
RUN mkdir -p bin
# Copy minimal pubspec for echo server (relative to context root)
COPY mcp_echo_server/bin/mcp_echo_server.pubspec.yaml ./pubspec.yaml
# Copy source code needed by echo server (relative to context root)
COPY mcp_echo_server/bin/mcp_echo_server.dart ./bin/

# Get dependencies for Echo server ONLY
RUN dart pub get --verbose
# Compile Echo Server
RUN dart compile exe bin/mcp_echo_server.dart -o /output/mcp_echo_server_executable


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

# Build the Go application statically for Alpine
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /output/mcp_tcp_proxy_executable ./main.go


# Stage 3: Create the minimal runtime image
FROM alpine:latest

WORKDIR /app

# Install ca-certificates needed for potential HTTPS calls from Go/Dart runtime
# Also install bash, as some Dart executables might implicitly rely on it
RUN apk update && apk add --no-cache ca-certificates bash

# Create a non-root user for security
RUN addgroup -S appgroup && adduser -S -G appgroup appuser

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

# Switch to the non-root user
USER appuser

# Set the entrypoint using the reliable /bin/sh -c method for variable expansion
ENTRYPOINT ["/bin/sh", "-c", "/app/mcp_tcp_proxy_executable --port $PROXY_PORT"]
