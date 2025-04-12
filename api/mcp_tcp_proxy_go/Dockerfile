# Stage 1: Build Go proxy AND Dart stdio servers
# Use an image containing both Go and Dart/Flutter SDKs
FROM cirrusci/flutter:stable AS builder

# Install Go (Alpine doesn't have it by default in this image)
# Check available Go version if specific one needed, e.g., apk add go~1.22
# Using 'go' package usually gets a recent stable version.
RUN apk update && apk add --no-cache go git

WORKDIR /build

# --- Setup Go ---
# Set GOPATH and add Go bin to PATH (optional but good practice)
ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH
RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"
WORKDIR $GOPATH/src/proxy

# Copy Go module files first for caching
COPY api/mcp_tcp_proxy_go/go.mod api/mcp_tcp_proxy_go/go.sum* ./
RUN go mod download

# Copy Go source code
COPY api/mcp_tcp_proxy_go/. .

# Build the Go proxy statically for Alpine
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o /app/mcp_tcp_proxy_executable ./main.go


# --- Setup Dart ---
WORKDIR /build/flutter_app # Use a different directory for Dart project

# Create a non-root user (optional but good practice for pub get/compile)
# RUN addgroup -S appgroup && adduser -S -G appgroup appuser
# RUN chown -R appuser:appgroup /build/flutter_app
# USER appuser

# Copy Dart project files (relative to build context root)
COPY pubspec.* ./
COPY bin ./bin
COPY lib ./lib
COPY mcp_echo_server ./mcp_echo_server
# Note: No need to copy api/mcp_tcp_proxy_go here as it's handled above

# Get Dart dependencies for the main project and servers
RUN dart pub get --verbose

# --- Compile Dart Executables ---
# Create output directory
RUN mkdir -p /app/bin

# Compile Todoist Server (for Linux)
RUN dart compile exe bin/todoist_mcp_server.dart -o /app/bin/todoist_mcp_server_executable

# Compile Echo Server (for Linux)
RUN dart compile exe mcp_echo_server/bin/mcp_echo_server.dart -o /app/bin/mcp_echo_server_executable

# --- Stage 2: Create the minimal runtime image ---
FROM alpine:latest

WORKDIR /app

# Create a non-root user for security
RUN addgroup -S appgroup && adduser -S -G appgroup appuser

# Copy the compiled Go proxy executable from the builder stage
COPY --from=builder /app/mcp_tcp_proxy_executable /app/
# Copy the compiled Dart stdio server executables from the builder stage
COPY --from=builder /app/bin/ /app/bin/

# Ensure all executables are runnable by the appuser
RUN chown -R appuser:appgroup /app && \
    chmod +x /app/mcp_tcp_proxy_executable && \
    chmod +x /app/bin/*

# Define the default port
ENV PROXY_PORT=8999
EXPOSE $PROXY_PORT

# Switch to the non-root user
USER appuser

# Set the entrypoint to run the Go proxy executable
ENTRYPOINT ["/app/mcp_tcp_proxy_executable", "--port", "$PROXY_PORT"]