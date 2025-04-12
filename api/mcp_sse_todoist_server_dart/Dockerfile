# Use the official Dart SDK image
FROM dart:stable AS build

# Set base working directory
WORKDIR /app

# Copy only necessary files first to leverage Docker cache

# Copy the server's pubspec files into its subdirectory within the container
COPY api/mcp_sse_todoist_server_dart/pubspec.yaml api/mcp_sse_todoist_server_dart/pubspec.lock ./api/mcp_sse_todoist_server_dart/

# Copy the local generated API client code into its subdirectory within the container
# This ensures the relative path in the server's pubspec works
COPY lib/todoist_api/ ./lib/todoist_api/

# Change WORKDIR to the server's directory to run pub get
WORKDIR /app/api/mcp_sse_todoist_server_dart

# Get dependencies (ONLINE - remove --offline)
# This will fetch mcp_dart, http, and resolve the local todoist_api path dependency
# because ../../lib/todoist_api/ relative to /app/api/mcp_sse_todoist_server_dart/ points to /app/lib/todoist_api/
RUN dart pub get

# Copy the rest of the server's application code into its directory
# Use ./ as source because the context is the project root, copy into current WORKDIR
COPY api/mcp_sse_todoist_server_dart/ ./

# Optional: Reset WORKDIR back to /app if preferred, but not strictly necessary here
# WORKDIR /app

# Verify entrypoint exists (optional sanity check, path relative to current WORKDIR)
RUN if [ ! -f bin/todoist_mcp_server.dart ]; then echo "Error: Entrypoint not found in /app/api/mcp_sse_todoist_server_dart/bin/"; exit 1; fi

# --- Runtime Stage ---
# Use the same Dart image version
FROM dart:stable

WORKDIR /app

# Copy built artifacts and dependencies from the build stage, maintaining structure
COPY --from=build /app /app
# Copy the pub cache from the build stage to the final stage
COPY --from=build /root/.pub-cache /root/.pub-cache

# Expose the port the SSE server will listen on (default 9000, matches server code)
EXPOSE 9000

# Define the entrypoint to run the server *in SSE mode*
# Path is now relative to the WORKDIR /app, pointing into the server's subdirectory
ENTRYPOINT ["dart", "run", "/app/api/mcp_sse_todoist_server_dart/bin/todoist_mcp_server.dart", "--transport=sse"]
