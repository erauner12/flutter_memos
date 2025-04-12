# Use the official Dart SDK image - Use a specific stable version for reproducibility
FROM dart:stable AS build

WORKDIR /app

# Copy only necessary files first to leverage Docker cache
# Assuming this Dockerfile is built with the project root (flutter_memos) as context
COPY pubspec.yaml pubspec.lock ./
# If todoist_api is a local path dependency, copy it here.
# Example: COPY todoist_api ./todoist_api/
# If flutter_memos/services is needed by the server (it seems so), copy lib
COPY lib ./lib/

# Get dependencies
RUN dart pub get --offline

# Copy the rest of the required application code AFTER pub get
COPY bin/todoist_mcp_server.dart ./bin/
# Ensure lib is copied if not done earlier
# COPY lib ./lib/

# Verify entrypoint exists (optional sanity check)
RUN if [ ! -f /app/bin/todoist_mcp_server.dart ]; then echo "Error: Entrypoint not found"; exit 1; fi

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
# Pass the --transport=sse flag
ENTRYPOINT ["dart", "run", "/app/bin/todoist_mcp_server.dart", "--transport=sse"]
