# Use the official Dart SDK image
FROM dart:stable AS build

WORKDIR /app

# Copy only necessary files first to leverage Docker cache
COPY pubspec.* ./
RUN dart pub get

# Copy the rest of the application code
COPY . .

# Ensure the entrypoint script is executable (if it exists in this stage)
# Note: The bin directory is copied with 'COPY . .'
RUN if [ -f /app/bin/mcp_sse_time_server.dart ]; then chmod +x /app/bin/mcp_sse_time_server.dart; fi

# Build the application (optional, can run directly from source)
# If compiling:
# RUN dart compile exe bin/mcp_sse_time_server.dart -o bin/server
# If running from source, skip compile step

# Use a smaller base image for the final stage
FROM dart:stable

WORKDIR /app

# Copy artifacts from the build stage
COPY --from=build /app /app

# Expose the port the server listens on (default 8999)
EXPOSE 8999

# Define the entrypoint to run the server from source
# If compiled, use: ENTRYPOINT ["/app/bin/server"]
ENTRYPOINT ["dart", "run", "/app/bin/mcp_sse_time_server.dart"]
