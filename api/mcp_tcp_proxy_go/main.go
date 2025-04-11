package main

import (
	"bufio"
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
)

// Configuration mapping tool names to the command path *inside the container*
// These paths must match where the Dart executables are copied in the Dockerfile
var toolToServerCommand = map[string]string{
	"echo":                  "/app/bin/mcp_echo_server_executable",
	"create_todoist_task":   "/app/bin/todoist_mcp_server_executable",
	"update_todoist_task":   "/app/bin/todoist_mcp_server_executable",
	"get_todoist_tasks":     "/app/bin/todoist_mcp_server_executable",
	"todoist_delete_task":   "/app/bin/todoist_mcp_server_executable",
	"todoist_complete_task": "/app/bin/todoist_mcp_server_executable",
	"get_todoist_task_by_id": "/app/bin/todoist_mcp_server_executable",
	"get_task_comments":     "/app/bin/todoist_mcp_server_executable",
	"create_task_comment":   "/app/bin/todoist_mcp_server_executable",
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

const (
	parseErrorCode      = -32700
	invalidRequestCode  = -32600
	methodNotFoundCode  = -32601
	internalErrorCode   = -32603
	serverErrorCodeBase = -32000
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
			if opErr, ok := err.(*net.OpError); ok && opErr.Err.Error() == "use of closed network connection" {
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

	for {
		// Read messages delimited by newline
		messageBytes, err := reader.ReadBytes('\n')
		if err != nil {
			if err != io.EOF { // EOF is expected when client disconnects cleanly
				log.Printf("[TCP Proxy GO] Error reading from client %s: %v", clientDesc, err)
			} else {
				log.Printf("[TCP Proxy GO] Client %s closed connection (EOF).", clientDesc)
			}
			break // Exit loop on error or EOF
		}

		// Trim trailing newline before processing
		messageString := strings.TrimSpace(string(messageBytes))
		if messageString == "" {
			continue // Ignore empty lines
		}

		log.Printf("[TCP Proxy GO] Received raw from %s: %s", clientDesc, messageString)

		// Handle the request asynchronously (optional, but good for long-running tools)
		go handleMcpRequest(messageString, conn, clientDesc)
	}
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
	reqID = req.ID // Store ID after successful basic parse

	log.Printf("[TCP Proxy GO] Parsed request ID %v, Method %s from %s", reqID, req.Method, clientDesc)

	// --- Routing Logic ---
	switch req.Method {
	case "tools/call":
		handleToolCall(messageJsonString, req, clientConn, clientDesc)
	case "tools/list":
		handleToolList(req, clientConn, clientDesc)
	// Add cases for other methods like "initialize", "ping" if needed
	default:
		log.Printf("[TCP Proxy GO] Method not found: %s from %s", req.Method, clientDesc)
		sendErrorResponse(clientConn, reqID, methodNotFoundCode, "Method not found", nil)
	}
}

// Handles a "tools/call" request
func handleToolCall(originalRequestJson string, req mcpRequest, clientConn net.Conn, clientDesc string) {
	var callParams struct {
		Name      string            `json:"name"`
		Arguments json.RawMessage `json:"arguments"` // Keep args raw for now
	}

	err := json.Unmarshal(req.Params, &callParams)
	if err != nil {
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
	cmd := exec.Command(serverCmdPath)

	// Prepare environment variables
	cmd.Env = os.Environ() // Inherit proxy's environment (includes TODOIST_API_TOKEN etc. from docker-compose)
	// Add/override specific env vars if needed:
	// cmd.Env = append(cmd.Env, "MY_VAR=some_value")

	stdinPipe, err := cmd.StdinPipe()
	if err != nil {
		log.Printf("[TCP Proxy GO] Error creating stdin pipe for %s: %v", serverCmdPath, err)
		sendErrorResponse(clientConn, req.ID, internalErrorCode, "Failed to start tool server", nil)
		return
	}
	stdoutPipe, err := cmd.StdoutPipe()
	if err != nil {
		log.Printf("[TCP Proxy GO] Error creating stdout pipe for %s: %v", serverCmdPath, err)
		sendErrorResponse(clientConn, req.ID, internalErrorCode, "Failed to start tool server", nil)
		return
	}
	stderrPipe, err := cmd.StderrPipe()
	if err != nil {
		log.Printf("[TCP Proxy GO] Error creating stderr pipe for %s: %v", serverCmdPath, err)
		sendErrorResponse(clientConn, req.ID, internalErrorCode, "Failed to start tool server", nil)
		return
	}

	// Start the command
	err = cmd.Start()
	if err != nil {
		log.Printf("[TCP Proxy GO] Error starting command %s: %v", serverCmdPath, err)
		sendErrorResponse(clientConn, req.ID, internalErrorCode, "Failed to start tool server process", nil)
		return
	}
	log.Printf("[TCP Proxy GO] Started subprocess PID %d for %s", cmd.Process.Pid, serverCmdPath)

	// Goroutine to log stderr from the subprocess
	go func() {
		scanner := bufio.NewScanner(stderrPipe)
		for scanner.Scan() {
			log.Printf("[Subprocess %d stderr] %s", cmd.Process.Pid, scanner.Text())
		}
	}()

	// Write the original request JSON to the subprocess's stdin
	// Important: Include the newline character!
	_, err = io.WriteString(stdinPipe, originalRequestJson+"\n")
	if err != nil {
		log.Printf("[TCP Proxy GO] Error writing to stdin of PID %d: %v", cmd.Process.Pid, err)
		cmd.Process.Kill() // Kill process if we can't write to it
		sendErrorResponse(clientConn, req.ID, internalErrorCode, "Error communicating with tool server", nil)
		return
	}
	stdinPipe.Close() // Close stdin to signal end of input

	// Read the response JSON from the subprocess's stdout (expects one line)
	responseReader := bufio.NewReader(stdoutPipe)
	responseBytes, err := responseReader.ReadBytes('\n')

	// Wait for the process to finish and check exit code *after* reading stdout
	waitErr := cmd.Wait()

	if err != nil && err != io.EOF { // EOF might happen if process exits without newline
		log.Printf("[TCP Proxy GO] Error reading stdout from PID %d: %v", cmd.Process.Pid, err)
		// Don't send error yet, check waitErr first
	}

	if waitErr != nil {
		log.Printf("[TCP Proxy GO] Subprocess PID %d exited with error: %v", cmd.Process.Pid, waitErr)
		// If we didn't get a response OR the process errored, send internal error
		if len(responseBytes) == 0 || err != nil {
			sendErrorResponse(clientConn, req.ID, internalErrorCode, "Tool server exited unexpectedly", fmt.Sprintf("%v", waitErr))
			return
		}
		// If we got a response but the process still errored, log it but proceed with the response
		log.Printf("[TCP Proxy GO] Warning: Subprocess PID %d exited with error but provided a response.", cmd.Process.Pid)
	} else {
		log.Printf("[TCP Proxy GO] Subprocess PID %d exited successfully.", cmd.Process.Pid)
	}

	if len(responseBytes) == 0 {
		log.Printf("[TCP Proxy GO] No response received from stdout of PID %d", cmd.Process.Pid)
		sendErrorResponse(clientConn, req.ID, internalErrorCode, "No response from tool server", nil)
		return
	}

	// Forward the raw response (including newline) back to the client
	log.Printf("[TCP Proxy GO] Forwarding response from PID %d to client %s", cmd.Process.Pid, clientDesc)
	_, writeErr := clientConn.Write(responseBytes)
	if writeErr != nil {
		log.Printf("[TCP Proxy GO] Error writing response to client %s: %v", clientDesc, writeErr)
		// Client connection might be dead, can't send error back
	}
}

// Handles a "tools/list" request by querying all configured servers
func handleToolList(req mcpRequest, clientConn net.Conn, clientDesc string) {
	log.Printf("[TCP Proxy GO] Handling tools/list request from %s", clientDesc)

	var allTools []map[string]interface{} // Store tools from all servers
	var wg sync.WaitGroup
	var mu sync.Mutex // Mutex to protect access to allTools slice

	listRequestJson := fmt.Sprintf(`{"jsonrpc":"2.0","method":"tools/list","id":%s}`+"\n", string(req.ID)) // Use client's ID? Or generate new? Using client's ID for now.

	for _, serverCmdPath := range serversToListTools {
		wg.Add(1)
		go func(cmdPath string) {
			defer wg.Done()
			log.Printf("[TCP Proxy GO] Querying tools/list from %s", cmdPath)

			cmd := exec.Command(cmdPath)
			cmd.Env = os.Environ() // Pass environment

			stdinPipe, _ := cmd.StdinPipe() // Error handling omitted for brevity here, add in real code
			stdoutPipe, _ := cmd.StdoutPipe()
			stderrPipe, _ := cmd.StderrPipe() // Capture stderr

			err := cmd.Start()
			if err != nil {
				log.Printf("[TCP Proxy GO] Error starting %s for tools/list: %v", cmdPath, err)
				return
			}
			pid := cmd.Process.Pid

			// Log stderr
			go func() {
				scanner := bufio.NewScanner(stderrPipe)
				for scanner.Scan() {
					log.Printf("[Subprocess %d stderr] %s", pid, scanner.Text())
				}
			}()

			_, err = io.WriteString(stdinPipe, listRequestJson)
			if err != nil {
				log.Printf("[TCP Proxy GO] Error writing tools/list request to PID %d: %v", pid, err)
				cmd.Process.Kill()
				return
			}
			stdinPipe.Close()

			responseReader := bufio.NewReader(stdoutPipe)
			responseBytes, err := responseReader.ReadBytes('\n')
			waitErr := cmd.Wait() // Wait after reading

			if err != nil && err != io.EOF {
				log.Printf("[TCP Proxy GO] Error reading tools/list response from PID %d: %v", pid, err)
				return
			}
			if waitErr != nil {
				log.Printf("[TCP Proxy GO] Subprocess PID %d for tools/list exited with error: %v", pid, waitErr)
				// Don't return error to client, just log, maybe one server failed
				return
			}

			// Parse the response to get the tools list
			var listResponse struct {
				Result struct {
					Tools []map[string]interface{} `json:"tools"`
				} `json:"result"`
			}
			err = json.Unmarshal(responseBytes, &listResponse)
			if err != nil {
				log.Printf("[TCP Proxy GO] Error parsing tools/list response JSON from PID %d: %v. Raw: %s", pid, err, string(responseBytes))
				return
			}

			// Add tools to the shared list safely
			mu.Lock()
			allTools = append(allTools, listResponse.Result.Tools...)
			mu.Unlock()
			log.Printf("[TCP Proxy GO] Got %d tools from %s", len(listResponse.Result.Tools), cmdPath)

		}(serverCmdPath)
	}

	wg.Wait() // Wait for all goroutines to finish

	// --- Send aggregated response ---
	finalResponse := map[string]interface{}{
		"jsonrpc": "2.0",
		"id":      req.ID,
		"result": map[string]interface{}{
			"tools": allTools,
		},
	}

	responseBytes, err := json.Marshal(finalResponse)
	if err != nil {
		log.Printf("[TCP Proxy GO] Error marshalling final tools/list response: %v", err)
		sendErrorResponse(clientConn, req.ID, internalErrorCode, "Failed to assemble tool list", nil)
		return
	}

	log.Printf("[TCP Proxy GO] Sending aggregated tools/list response to %s (%d tools)", clientDesc, len(allTools))
	_, writeErr := clientConn.Write(append(responseBytes, '\n')) // Add newline
	if writeErr != nil {
		log.Printf("[TCP Proxy GO] Error writing tools/list response to client %s: %v", clientDesc, writeErr)
	}
}

// Helper to send a JSON-RPC error response
func sendErrorResponse(conn net.Conn, id interface{}, code int, message string, data interface{}) {
	errResp := mcpErrorResponse{
		Jsonrpc: "2.0",
		ID:      id,
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
		conn.Write([]byte(fmt.Sprintf("Error: %s\n", message)))
		return
	}
	_, writeErr := conn.Write(append(respBytes, '\n')) // Add newline
	if writeErr != nil {
		log.Printf("[TCP Proxy GO] Failed to write error response to client: %v", writeErr)
	}
}
