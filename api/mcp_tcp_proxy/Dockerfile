# Use an official Dart runtime base image
FROM dart:stable AS runtime

WORKDIR /app

# Copy only the compiled executables from the bin directory
# Assumes you have compiled them into mcp_tcp_proxy/bin/ beforehand
COPY ./bin/mcp_echo_server_executable /app/bin/
COPY ./bin/todoist_mcp_server_executable /app/bin/
COPY ./bin/mcp_tcp_proxy_executable /app/bin/

# Make executables runnable
RUN chmod +x /app/bin/*

# Define the default port the proxy will listen on inside the container
ENV PROXY_PORT=8999
EXPOSE $PROXY_PORT

# Set the entrypoint to run the proxy executable
# Pass the port using the environment variable
ENTRYPOINT ["/app/bin/mcp_tcp_proxy_executable", "--port", "$PROXY_PORT"]
