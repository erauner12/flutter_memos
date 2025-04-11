# Stage 1: Build the Go proxy executable
FROM golang:1.22-alpine AS builder
# FROM golang:1.21-alpine AS builder # Use 1.21 if your go.mod specifies it

WORKDIR /src

# Copy Go module files and download dependencies first (cache layer)
COPY go.mod go.sum* ./
RUN go mod download

# Copy the Go source code
COPY . .

# Build the Go application statically
# CGO_ENABLED=0 disables Cgo, needed for static builds on Alpine
# -ldflags="-s -w" strips debug symbols and DWARF info for smaller binary
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o /app/mcp_tcp_proxy_executable ./main.go

# --- Copy Pre-compiled Dart Executables ---
# These need to be copied from your host *into* the builder stage
# Adjust the source path ('../../compiled_dart_bins/') relative to this Dockerfile's location
COPY ../../compiled_dart_bins/mcp_echo_server_executable /app/bin/
COPY ../../compiled_dart_bins/todoist_mcp_server_executable /app/bin/
# Add other Dart executables if needed


# Stage 2: Create the minimal runtime image
FROM alpine:latest
# FROM scratch # For ultra-minimal image, but requires static Go binary and no shell access

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
