# Stage 1: Compile Dart stdio servers for Linux
FROM dart:stable AS dart-builder

WORKDIR /app

# Install certs if needed for pub get (though less likely than in previous attempts)
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates && rm -rf /var/lib/apt/lists/*

# Copy only necessary Dart project files
COPY pubspec.* ./
COPY lib ./lib
COPY bin ./bin
COPY mcp_echo_server ./mcp_echo_server
# Copy the todoist API dependency if it's separate
# COPY todoist_api ./todoist_api # Uncomment if needed

# Get dependencies
RUN dart pub get --verbose

# Create output directory
RUN mkdir /output

# Compile Dart servers for Linux target
RUN dart compile exe bin/todoist_mcp_server.dart -o /output/todoist_mcp_server_executable
RUN dart compile exe mcp_echo_server/bin/mcp_echo_server.dart -o /output/mcp_echo_server_executable


# Stage 2: Build the Go proxy executable
FROM golang:1.22-alpine AS go-builder
# FROM golang:1.21-alpine AS go-builder

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
