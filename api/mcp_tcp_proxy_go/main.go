package main

import (
	"bufio"
	"bytes" // Needed for stdout buffer
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log"
	"net"
	"os"
	"os/exec"
	"os/signal"
	"strings"
	"sync"
	"syscall"
	// Added for potential timeouts
)

// Configuration mapping tool names to the command path *inside the container*
// These paths must match where the Dart executables are copied in the Dockerfile
var toolToServerCommand = map[string]string{
	"echo":                   "/app/bin/mcp_echo_server_executable",
	"create_todoist_task":    "/app/bin/todoist_mcp_server_executable",
	"update_todoist_task":    "/app/bin/todoist_mcp_server_executable",
	"get_todoist_tasks":      "/app/bin/todoist_mcp_server_executable",
	"todoist_delete_task":    "/app/bin/todoist_mcp_server_executable",
	"todoist_complete_task":  "/app/bin/todoist_mcp_server_executable",
	"get_todoist_task_by_id": "/app/bin/todoist_mcp_server_executable",
	"get_task_comments":      "/app/bin/todoist_mcp_server_executable",
	"create_task_comment":    "/app/bin/todoist_mcp_server_executable",
	// Add other tools if needed
}

// List of server executables to query for "tools/list"
var serversToListTools []string

func init() {
	// Populate serversToListTools dynamically from the map values (unique paths)
	serverSet := make(map[string]struct{})
	for _, cmdPath := range toolToServerCommand {
		serverSet[cmdPath] = struct{}{}
	}
	for cmdPath := range serverSet {
		serversToListTools = append(serversToListTools, cmdPath)
	}
	log.SetFlags(log.LstdFlags | log.Lmicroseconds) // Add microseconds to logs
}

// Simple struct to represent a parsed MCP request (only need method and id for routing)
type mcpRequest struct {
	Jsonrpc string          `json:"jsonrpc"`
	Method  string          `json:"method"`
	ID      json.RawMessage `json:"id"` // Keep ID as raw JSON to echo back
	Params  json.RawMessage `json:"params"`
}

// Simple struct for MCP error response
type mcpErrorResponse struct {
	Jsonrpc string      `json:"jsonrpc"`
	ID      interface{} `json:"id"` // Can be null for parse errors before ID is known
	Error   mcpError    `json:"error"`
}

type mcpError struct {
	Code    int         `json:"code"`
	Message string      `json:"message"`
	Data    interface{} `json:"data,omitempty"`
}

// Struct for successful MCP response result
type mcpSuccessResponse struct {
	Jsonrpc string      `json:"jsonrpc"`
	ID      interface{} `json:"id"`
	Result  interface{} `json:"result"`
}

const (
	parseErrorCode     = -32700
	invalidRequestCode = -32600
	methodNotFoundCode = -32601
	internalErrorCode  = -32603
	// serverErrorCodeBase = -32000 // Not used directly here yet
)

func main() {
	port := flag.String("port", "8999", "Port to listen on")
	flag.Parse()

	listener, err := net.Listen("tcp", ":"+*port)
	if err != nil {
		log.Fatalf("[TCP Proxy GO] FATAL: Could not listen on port %s: %v", *port, err)
	}
	defer listener.Close()
	log.Printf("[TCP Proxy GO] Listening on port %s...", *port)

	// Handle graceful shutdown
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)
	go func() {
		sig := <-sigChan
		log.Printf("[TCP Proxy GO] Received signal %v, shutting down...", sig)
		listener.Close() // This will cause the Accept loop to break
		// Add cleanup for active connections if needed
		os.Exit(0)
	}()

	// Accept connections in a loop
	for {
		conn, err := listener.Accept()
		if err != nil {
			// Check if the error is due to the listener being closed
			if opErr, ok := err.(*net.OpError); ok && (strings.Contains(opErr.Err.Error(), "use of closed network connection") || strings.Contains(opErr.Err.Error(), "invalid argument")) {
				log.Println("[TCP Proxy GO] Listener closed, exiting accept loop.")
				break // Exit loop gracefully
			}
			log.Printf("[TCP Proxy GO] Error accepting connection: %v", err)
			continue // Continue accepting other connections
		}
		clientDesc := conn.RemoteAddr().String()
		log.Printf("[TCP Proxy GO] Client connected: %s", clientDesc)
		go handleClient(conn, clientDesc) // Handle each client in a goroutine
	}
	log.Println("[TCP Proxy GO] Server stopped.")
}

// Handles a single client connection
func handleClient(conn net.Conn, clientDesc string) {
	defer conn.Close()
	defer log.Printf("[TCP Proxy GO] Client disconnected: %s", clientDesc)

	reader := bufio.NewReader(conn)
	// Use a channel to signal when request handling is done for this connection
	// This helps manage goroutines if needed, though currently each request gets its own
	// doneChan := make(chan bool)

	for {
		// Read messages delimited by newline
		messageBytes, err := reader.ReadBytes('\n')
		if err != nil {
			if err != io.EOF && !strings.Contains(err.Error(), "use of closed network connection") {
				log.Printf("[TCP Proxy GO] Error reading from client %s: %v", clientDesc, err)
			} else {
				log.Printf("[TCP Proxy GO] Client %s closed connection.", clientDesc)
			}
			break // Exit loop on error or EOF
		}

		// Trim trailing newline before processing
		messageString := strings.TrimSpace(string(messageBytes))
		if messageString == "" {
			continue // Ignore empty lines
		}

		log.Printf("[TCP Proxy GO] Received raw from %s: %s", clientDesc, messageString)

		// Handle the request asynchronously
		// Pass the connection so the handler can write back
		go handleMcpRequest(messageString, conn, clientDesc)
	}
	// close(doneChan) // Signal that this client handler is finished
}

// Parses the MCP request and routes it to the appropriate stdio server
func handleMcpRequest(messageJsonString string, clientConn net.Conn, clientDesc string) {
	var req mcpRequest
	var reqID interface{} // Use interface{} to handle potential null ID on parse error

	// Attempt to parse the basic request structure first
	err := json.Unmarshal([]byte(messageJsonString), &req)
	if err != nil {
		log.Printf("[TCP Proxy GO] Error parsing JSON from %s: %v. Raw: %s", clientDesc, err, messageJsonString)
		sendErrorResponse(clientConn, nil, parseErrorCode, "Parse error", nil) // ID is null here
		return
	}
	// Attempt to unmarshal the ID specifically to preserve its type (number or string)
	// If ID is missing or null in the JSON, reqID will remain nil
	_ = json.Unmarshal(req.ID, &reqID)

	log.Printf("[TCP Proxy GO] Parsed request ID %v, Method %s from %s", reqID, req.Method, clientDesc)

	// --- Routing Logic ---
	switch req.Method {
	case "initialize":
		// Handle initialize directly in the proxy if needed, or just ignore/pass through
		// For now, send a basic success response mimicking a simple server
		log.Printf("[TCP Proxy GO] Handling initialize request from %s", clientDesc)
		sendInitializeResponse(clientConn, reqID)
	case "ping":
		log.Printf("[TCP Proxy GO] Handling ping request from %s", clientDesc)
		sendSuccessResponse(clientConn, reqID, map[string]interface{}{}) // Empty result for ping
	case "tools/call":
		handleToolCall(messageJsonString, req, clientConn, clientDesc)
	case "tools/list":
		handleToolList(req, clientConn, clientDesc)
	// Add cases for other methods like "notifications/initialized" (ignore?)
	case "notifications/initialized":
		log.Printf("[TCP Proxy GO] Received initialized notification from %s. Ignoring.", clientDesc)
		// No response needed for notifications
	default:
		log.Printf("[TCP Proxy GO] Method not found: %s from %s", req.Method, clientDesc)
		sendErrorResponse(clientConn, reqID, methodNotFoundCode, "Method not found", nil)
	}
}

// Handles a "tools/call" request
func handleToolCall(originalRequestJson string, req mcpRequest, clientConn net.Conn, clientDesc string) {
	var callParams struct {
		Name      string            `json:"name"`
		Arguments json.RawMessage `json:"arguments"` // Keep args raw
	}

	if err := json.Unmarshal(req.Params, &callParams); err != nil {
		log.Printf("[TCP Proxy GO] Error parsing tools/call params from %s: %v", clientDesc, err)
		sendErrorResponse(clientConn, req.ID, invalidRequestCode, "Invalid parameters for tools/call", nil)
		return
	}

	toolName := callParams.Name
	serverCmdPath, found := toolToServerCommand[toolName]
	if !found {
		log.Printf("[TCP Proxy GO] Tool '%s' not mapped to a server command for client %s", toolName, clientDesc)
		sendErrorResponse(clientConn, req.ID, methodNotFoundCode, fmt.Sprintf("Tool '%s' not found", toolName), nil)
		return
	}

	log.Printf("[TCP Proxy GO] Routing tool '%s' to command '%s' for client %s", toolName, serverCmdPath, clientDesc)

	// --- Execute Stdio Server ---
	responseBytes, err := executeStdioServer(serverCmdPath, originalRequestJson)
	if err != nil {
		log.Printf("[TCP Proxy GO] Error executing stdio server %s for tool '%s': %v", serverCmdPath, toolName, err)
		sendErrorResponse(clientConn, req.ID, internalErrorCode, fmt.Sprintf("Error executing tool '%s'", toolName), err.Error())
		return
	}

	// Forward the raw response (including newline) back to the client
	log.Printf("[TCP Proxy GO] Forwarding response for tool '%s' to client %s", toolName, clientDesc)
	_, writeErr := clientConn.Write(responseBytes)
	if writeErr != nil {
		log.Printf("[TCP Proxy GO] Error writing response to client %s: %v", clientDesc, writeErr)
		// Client connection might be dead
	}
}

// Handles a "tools/list" request by querying all configured servers
func handleToolList(req mcpRequest, clientConn net.Conn, clientDesc string) {
	log.Printf("[TCP Proxy GO] Handling tools/list request from %s", clientDesc)

	var allTools []map[string]interface{} // Store tools from all servers
	var wg sync.WaitGroup
	var mu sync.Mutex // Mutex to protect access to allTools slice
	var errors []string // Collect errors from subprocesses

	// Use a unique ID for proxy's internal requests to servers? Or reuse client's?
	// Reusing client's ID might be simpler for now, assuming servers handle it.
	listRequestJson := fmt.Sprintf(`{"jsonrpc":"2.0","method":"tools/list","id":%s}`+"\n", string(req.ID))

	for _, serverCmdPath := range serversToListTools {
		wg.Add(1)
		go func(cmdPath string) {
			defer wg.Done()
			log.Printf("[TCP Proxy GO] Querying tools/list from %s", cmdPath)

			responseBytes, err := executeStdioServer(cmdPath, listRequestJson)
			if err != nil {
				log.Printf("[TCP Proxy GO] Error executing %s for tools/list: %v", cmdPath, err)
				mu.Lock()
				errors = append(errors, fmt.Sprintf("Server %s failed: %v", cmdPath, err))
				mu.Unlock()
				return
			}

			// Parse the response to get the tools list
			var listResponse struct {
				// Use json.RawMessage for ID to handle string or number
				ID     json.RawMessage `json:"id"`
				Result struct {
					Tools []map[string]interface{} `json:"tools"`
				} `json:"result"`
				Error *mcpError `json:"error,omitempty"` // Pointer to handle potential error response from server
			}
			if err := json.Unmarshal(responseBytes, &listResponse); err != nil {
				log.Printf("[TCP Proxy GO] Error parsing tools/list response JSON from %s: %v. Raw: %s", cmdPath, err, string(responseBytes))
				mu.Lock()
				errors = append(errors, fmt.Sprintf("Server %s invalid response: %v", cmdPath, err))
				mu.Unlock()
				return
			}

			// Check if the server returned an error in the JSON-RPC response
			if listResponse.Error != nil {
				log.Printf("[TCP Proxy GO] Server %s returned error for tools/list: %v", cmdPath, listResponse.Error.Message)
				mu.Lock()
				errors = append(errors, fmt.Sprintf("Server %s error: %s", cmdPath, listResponse.Error.Message))
				mu.Unlock()
				return
			}

			// Add tools to the shared list safely
			if len(listResponse.Result.Tools) > 0 {
				mu.Lock()
				allTools = append(allTools, listResponse.Result.Tools...)
				mu.Unlock()
				log.Printf("[TCP Proxy GO] Got %d tools from %s", len(listResponse.Result.Tools), cmdPath)
			} else {
				log.Printf("[TCP Proxy GO] Got 0 tools from %s", cmdPath)
			}

		}(serverCmdPath)
	}

	wg.Wait() // Wait for all goroutines to finish

	// --- Send aggregated response ---
	// Even if some servers failed, send back the tools we did get
	log.Printf("[TCP Proxy GO] Aggregated %d tools total.", len(allTools))
	if len(errors) > 0 {
		log.Printf("[TCP Proxy GO] Errors encountered during tools/list: %s", strings.Join(errors, "; "))
		// Optionally include errors in the response metadata if the protocol supported it
	}

	sendSuccessResponse(clientConn, req.ID, map[string]interface{}{"tools": allTools})
}

// Executes a stdio server process, sends a request, and returns the response.
func executeStdioServer(serverCmdPath, requestJson string) ([]byte, error) {
	cmd := exec.Command(serverCmdPath)
	cmd.Env = os.Environ() // Inherit environment

	stdinPipe, err := cmd.StdinPipe()
	if err != nil {
		return nil, fmt.Errorf("error creating stdin pipe for %s: %w", serverCmdPath, err)
	}
	stdoutPipe, err := cmd.StdoutPipe()
	if err != nil {
		return nil, fmt.Errorf("error creating stdout pipe for %s: %w", serverCmdPath, err)
	}
	stderrPipe, err := cmd.StderrPipe()
	if err != nil {
		return nil, fmt.Errorf("error creating stderr pipe for %s: %w", serverCmdPath, err)
	}

	// Start the command
	if err := cmd.Start(); err != nil {
		return nil, fmt.Errorf("error starting command %s: %w", serverCmdPath, err)
	}
	pid := cmd.Process.Pid
	log.Printf("[TCP Proxy GO] Started subprocess PID %d for %s", pid, serverCmdPath)

	// Goroutine to log stderr
	var stderrOutput bytes.Buffer
	go func() {
		scanner := bufio.NewScanner(stderrPipe)
		for scanner.Scan() {
			line := scanner.Text()
			log.Printf("[Subprocess %d stderr] %s", pid, line)
			stderrOutput.WriteString(line + "\n") // Capture stderr
		}
	}()

	// Write request to stdin
	if _, err = io.WriteString(stdinPipe, requestJson); err != nil {
		cmd.Process.Kill() // Ensure process is killed
		cmd.Wait()         // Wait for resources to be released
		return nil, fmt.Errorf("error writing to stdin of PID %d: %w", pid, err)
	}
	// Close stdin *after* writing
	if err := stdinPipe.Close(); err != nil {
		log.Printf("[TCP Proxy GO] Warning: error closing stdin for PID %d: %v", pid, err)
		// Continue, maybe process already exited
	}

	// Read response from stdout
	responseReader := bufio.NewReader(stdoutPipe)
	responseBytes, readErr := responseReader.ReadBytes('\n') // Read until newline

	// Wait for the process to finish *after* attempting to read stdout
	waitErr := cmd.Wait()

	// --- Error Handling ---
	// Prioritize process exit error if we didn't get a response
	if waitErr != nil && (readErr != nil || len(responseBytes) == 0) {
		log.Printf("[TCP Proxy GO] Subprocess PID %d exited with error: %v. Stderr: %s", pid, waitErr, stderrOutput.String())
		return nil, fmt.Errorf("server process %s exited with error: %w. Stderr: %s", serverCmdPath, waitErr, stderrOutput.String())
	}
	// Handle read error if process exited cleanly but read failed
	if readErr != nil && readErr != io.EOF {
		log.Printf("[TCP Proxy GO] Error reading stdout from PID %d: %v. Stderr: %s", pid, readErr, stderrOutput.String())
		return nil, fmt.Errorf("error reading response from %s: %w. Stderr: %s", serverCmdPath, readErr, stderrOutput.String())
	}
	// Handle case where process exited cleanly but sent no response
	if len(responseBytes) == 0 {
		log.Printf("[TCP Proxy GO] No response received from stdout of PID %d. Stderr: %s", pid, stderrOutput.String())
		return nil, fmt.Errorf("no response from server %s. Stderr: %s", serverCmdPath, stderrOutput.String())
	}
	// Log success if process exited cleanly
	if waitErr == nil {
		log.Printf("[TCP Proxy GO] Subprocess PID %d exited successfully.", pid)
	} else {
		// Log warning if process errored but we still got a response
		log.Printf("[TCP Proxy GO] Warning: Subprocess PID %d exited with error (%v) but provided a response.", pid, waitErr)
	}


	return responseBytes, nil
}

// Helper to send a JSON-RPC error response
func sendErrorResponse(conn net.Conn, id interface{}, code int, message string, data interface{}) {
	errResp := mcpErrorResponse{
		Jsonrpc: "2.0",
		ID:      id, // Use the passed ID (can be nil for parse errors)
		Error: mcpError{
			Code:    code,
			Message: message,
			Data:    data,
		},
	}
	respBytes, err := json.Marshal(errResp)
	if err != nil {
		log.Printf("[TCP Proxy GO] CRITICAL: Failed to marshal error response: %v", err)
		// Attempt to send a plain text error if JSON fails
		_, _ = conn.Write([]byte(fmt.Sprintf("{\"jsonrpc\":\"2.0\",\"id\":null,\"error\":{\"code\":%d,\"message\":\"%s\"}}\n", internalErrorCode, "Proxy error marshalling response")))
		return
	}
	_, writeErr := conn.Write(append(respBytes, '\n')) // Add newline
	if writeErr != nil {
		// Log locally, can't send back to client if write fails
		log.Printf("[TCP Proxy GO] Failed to write error response to client: %v", writeErr)
	}
}

// Helper to send a JSON-RPC success response
func sendSuccessResponse(conn net.Conn, id interface{}, result interface{}) {
	resp := mcpSuccessResponse{
		Jsonrpc: "2.0",
		ID:      id,
		Result:  result,
	}
	respBytes, err := json.Marshal(resp)
	if err != nil {
		log.Printf("[TCP Proxy GO] Error marshalling success response: %v", err)
		// Try sending an internal error back to the client
		sendErrorResponse(conn, id, internalErrorCode, "Failed to marshal success response", err.Error())
		return
	}
	_, writeErr := conn.Write(append(respBytes, '\n')) // Add newline
	if writeErr != nil {
		log.Printf("[TCP Proxy GO] Failed to write success response to client: %v", writeErr)
	}
}

// Specific handler for initialize response (mimics basic server)
func sendInitializeResponse(conn net.Conn, id interface{}) {
	// Define basic proxy capabilities (it doesn't really have MCP capabilities itself)
	// It just forwards tool calls.
	capabilities := map[string]interface{}{
		"tools": map[string]interface{}{}, // Indicate tool support is proxied
	}
	serverInfo := map[string]string{
		"name":    "mcp-tcp-proxy-go",
		"version": "0.1.0", // Example version
	}
	result := map[string]interface{}{
		"protocolVersion": "2024-11-05", // Use the latest known version
		"capabilities":    capabilities,
		"serverInfo":      serverInfo,
	}
	sendSuccessResponse(conn, id, result)
}
