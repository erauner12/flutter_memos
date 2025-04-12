# Use the official Dart SDK image
FROM dart:stable AS build

WORKDIR /app

# Copy only necessary files first to leverage Docker cache
# Copy this package's pubspec files
COPY pubspec.yaml pubspec.lock ./
# The path dependency in pubspec.yaml will handle copying flutter_memos code

# Get dependencies (ONLINE - remove --offline)
# This will fetch mcp_dart and resolve the flutter_memos path dependency
RUN dart pub get

# Copy the rest of the application code *from this directory's context*
COPY . .

# Verify entrypoint exists (optional sanity check)
RUN if [ ! -f /app/bin/todoist_mcp_server.dart ]; then echo "Error: Entrypoint not found in /app/bin/"; exit 1; fi
# Optional: Make executable if needed (dart run doesn't require it)
# RUN chmod +x /app/bin/todoist_mcp_server.dart

# --- Runtime Stage ---
# Use the same Dart image version
FROM dart:stable

WORKDIR /app

# Copy built artifacts and dependencies from the build stage
COPY --from=build /app /app
# Copy the pub cache from the build stage to the final stage
COPY --from=build /root/.pub-cache /root/.pub-cache

# Expose the port the SSE server will listen on (default 9000, matches server code)
EXPOSE 9000

# Define the entrypoint to run the server *in SSE mode*
# Path is now relative to the WORKDIR /app
ENTRYPOINT ["dart", "run", "/app/bin/todoist_mcp_server.dart", "--transport=sse"]
