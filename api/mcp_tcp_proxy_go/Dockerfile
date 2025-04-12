# Stage 1: Build the Go proxy executable
FROM golang:1.22-alpine AS builder
# FROM golang:1.21-alpine AS builder # Use 1.21 if your go.mod specifies it

WORKDIR /src

# Install ca-certificates, might be needed by Go for HTTPS calls during build (e.g., go mod download)
RUN apk update && apk add --no-cache ca-certificates git

# Copy Go module files and download dependencies first (cache layer)
# Source path is relative to the build context (project root)
COPY api/mcp_tcp_proxy_go/go.mod api/mcp_tcp_proxy_go/go.sum* ./
RUN go mod download

# Copy the Go source code from its subdirectory relative to the build context
COPY api/mcp_tcp_proxy_go/. .

# Build the Go application statically for Alpine
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /app/mcp_tcp_proxy_executable ./main.go

# --- Copy Pre-compiled Dart Executables from Host ---
# Source path is relative to the build context (project root)
# Copy them into a temporary location in the builder stage
RUN mkdir -p /app/dart_bins
COPY compiled_dart_bins/mcp_echo_server_executable /app/dart_bins/
COPY compiled_dart_bins/todoist_mcp_server_executable /app/dart_bins/
# Add other Dart executables if needed


# Stage 2: Create the minimal runtime image
FROM alpine:latest

WORKDIR /app

# Install ca-certificates needed for potential HTTPS calls from Go/Dart runtime
RUN apk update && apk add --no-cache ca-certificates

# Create a non-root user for security
RUN addgroup -S appgroup && adduser -S -G appgroup appuser

# Copy the compiled Go proxy executable from the builder stage
COPY --from=builder /app/mcp_tcp_proxy_executable /app/
# Copy the compiled Dart stdio server executables from the builder stage
COPY --from=builder /app/dart_bins/ /app/bin/

# Ensure all executables are runnable by the appuser
RUN chown -R appuser:appgroup /app && \
    chmod +x /app/mcp_tcp_proxy_executable && \
    chmod +x /app/bin/*

# Define the default port
ENV PROXY_PORT=8999
EXPOSE $PROXY_PORT

# Switch to the non-root user
USER appuser

# Set the entrypoint using shell form to ensure variable substitution
# Use /bin/sh -c to explicitly invoke a shell
ENTRYPOINT ["/bin/sh", "-c", "/app/mcp_tcp_proxy_executable --port $PROXY_PORT"]
