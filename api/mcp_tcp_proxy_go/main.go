package main

import (
	"bufio"
	"bytes"
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
	"time"
)

// Configuration mapping tool names to the command path *inside the container*
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
}

// List of server executables to query for "tools/list"
var serversToListTools []string

func init() {
	serverSet := make(map[string]struct{})
	for _, cmdPath := range toolToServerCommand {
		serverSet[cmdPath] = struct{}{}
	}
	for cmdPath := range serverSet {
		serversToListTools = append(serversToListTools, cmdPath)
	}
	log.SetFlags(log.LstdFlags | log.Lmicroseconds)
}

type mcpRequest struct {
	Jsonrpc string          `json:"jsonrpc"`
	Method  string          `json:"method"`
	ID      json.RawMessage `json:"id"`
	Params  json.RawMessage `json:"params"`
}

type mcpResponse struct {
	Jsonrpc string          `json:"jsonrpc"`
	ID      json.RawMessage `json:"id"`
	Result  json.RawMessage `json:"result,omitempty"`
	Error   *mcpError       `json:"error,omitempty"`
}

type mcpErrorResponse struct {
	Jsonrpc string      `json:"jsonrpc"`
	ID      interface{} `json:"id"` // Use interface{} for flexibility
	Error   mcpError    `json:"error"`
}

type mcpError struct {
	Code    int         `json:"code"`
	Message string      `json:"message"`
	Data    interface{} `json:"data,omitempty"`
}

type mcpSuccessResponse struct {
	Jsonrpc string      `json:"jsonrpc"`
	ID      interface{} `json:"id"` // Use interface{} for flexibility
	Result  interface{} `json:"result"`
}

const (
	parseErrorCode     = -32700
	invalidRequestCode = -32600
	methodNotFoundCode = -32601
	internalErrorCode  = -32603
	serverTimeoutCode  = -32001 // Custom code for server timeout
	handshakeTimeout   = 20 * time.Second // Increased timeout for handshake
	requestTimeout     = 60 * time.Second // Timeout for the actual request/response
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

	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)
	go func() {
		sig := <-sigChan
		log.Printf("[TCP Proxy GO] Received signal %v, shutting down...", sig)
		listener.Close()
		os.Exit(0)
	}()

	for {
		conn, err := listener.Accept()
		if err != nil {
			if opErr, ok := err.(*net.OpError); ok && (strings.Contains(opErr.Err.Error(), "use of closed network connection") || strings.Contains(opErr.Err.Error(), "invalid argument")) {
				log.Println("[TCP Proxy GO] Listener closed, exiting accept loop.")
				break
			}
			log.Printf("[TCP Proxy GO] Error accepting connection: %v", err)
			continue
		}
		clientDesc := conn.RemoteAddr().String()
		log.Printf("[TCP Proxy GO] Client connected: %s", clientDesc)
		go handleClient(conn, clientDesc)
	}
	log.Println("[TCP Proxy GO] Server stopped.")
}

func handleClient(conn net.Conn, clientDesc string) {
	defer conn.Close()
	defer log.Printf("[TCP Proxy GO] Client disconnected: %s", clientDesc)

	reader := bufio.NewReader(conn)
	for {
		messageBytes, err := reader.ReadBytes('\n')
		if err != nil {
			if err != io.EOF && !strings.Contains(err.Error(), "use of closed network connection") {
				log.Printf("[TCP Proxy GO] Error reading from client %s: %v", clientDesc, err)
			} else {
				log.Printf("[TCP Proxy GO] Client %s closed connection.", clientDesc)
			}
			break
		}

		messageString := strings.TrimSpace(string(messageBytes))
		if messageString == "" {
			continue
		}

		log.Printf("[TCP Proxy GO] Received raw from %s: %s", clientDesc, messageString)
		go handleMcpRequest(messageString, conn, clientDesc)
	}
}

func handleMcpRequest(messageJsonString string, clientConn net.Conn, clientDesc string) {
	var req mcpRequest
	var reqID interface{} // Use interface{} to handle potential null ID

	err := json.Unmarshal([]byte(messageJsonString), &req)
	if err != nil {
		log.Printf("[TCP Proxy GO] Error parsing JSON from %s: %v. Raw: %s", clientDesc, err, messageJsonString)
		sendErrorResponse(clientConn, nil, parseErrorCode, "Parse error", nil)
		return
	}
	// Unmarshal the ID separately to preserve its type (number or string or null)
	_ = json.Unmarshal(req.ID, &reqID)

	log.Printf("[TCP Proxy GO] Parsed request ID %v, Method %s from %s", reqID, req.Method, clientDesc)

	switch req.Method {
	case "initialize":
		log.Printf("[TCP Proxy GO] Handling initialize request from %s", clientDesc)
		sendInitializeResponse(clientConn, reqID) // Use parsed interface{} ID
	case "ping":
		log.Printf("[TCP Proxy GO] Handling ping request from %s", clientDesc)
		sendSuccessResponse(clientConn, reqID, map[string]interface{}{}) // Use parsed interface{} ID
	case "tools/call":
		handleToolCall(messageJsonString, req, clientConn, clientDesc)
	case "tools/list":
		handleToolList(req, clientConn, clientDesc)
	case "notifications/initialized":
		log.Printf("[TCP Proxy GO] Received initialized notification from %s. Ignoring.", clientDesc)
	default:
		log.Printf("[TCP Proxy GO] Method not found: %s from %s", req.Method, clientDesc)
		sendErrorResponse(clientConn, reqID, methodNotFoundCode, "Method not found", nil) // Use parsed interface{} ID
	}
}

func handleToolCall(originalRequestJson string, req mcpRequest, clientConn net.Conn, clientDesc string) {
	var callParams struct {
		Name string `json:"name"`
		// Arguments json.RawMessage `json:"arguments"` // Not needed for routing
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

	// Pass original request JSON (which includes the newline) and the original RawMessage ID
	responseBytes, err := executeStdioServer(serverCmdPath, originalRequestJson+"\n", req.ID)
	if err != nil {
		log.Printf("[TCP Proxy GO] Error executing stdio server %s for tool '%s': %v", serverCmdPath, toolName, err)
		sendErrorResponse(clientConn, req.ID, internalErrorCode, fmt.Sprintf("Error executing tool '%s'", toolName), err.Error())
		return
	}

	log.Printf("[TCP Proxy GO] Forwarding response for tool '%s' to client %s", toolName, clientDesc)
	_, writeErr := clientConn.Write(responseBytes) // responseBytes already includes newline
	if writeErr != nil {
		log.Printf("[TCP Proxy GO] Error writing response to client %s: %v", clientDesc, writeErr)
	}
}

func handleToolList(req mcpRequest, clientConn net.Conn, clientDesc string) {
	log.Printf("[TCP Proxy GO] Handling tools/list request from %s", clientDesc)

	var allTools []map[string]interface{}
	var wg sync.WaitGroup
	var mu sync.Mutex
	var errors []string

	// Create the tools/list request JSON using the client's request ID
	listRequestJsonBytes, _ := json.Marshal(map[string]interface{}{
		"jsonrpc": "2.0",
		"method":  "tools/list",
		"id":      req.ID, // Use the original RawMessage ID
	})
	listRequestJson := string(listRequestJsonBytes) + "\n" // Add newline

	for _, serverCmdPath := range serversToListTools {
		wg.Add(1)
		go func(cmdPath string) {
			defer wg.Done()
			log.Printf("[TCP Proxy GO] Querying tools/list from %s", cmdPath)

			// Execute server, passing the specific tools/list request and its RawMessage ID
			responseBytes, err := executeStdioServer(cmdPath, listRequestJson, req.ID)
			if err != nil {
				log.Printf("[TCP Proxy GO] Error executing %s for tools/list: %v", cmdPath, err)
				mu.Lock()
				errors = append(errors, fmt.Sprintf("Server %s failed: %v", cmdPath, err))
				mu.Unlock()
				return
			}

			var listResponse mcpResponse
			if err := json.Unmarshal(responseBytes, &listResponse); err != nil {
				log.Printf("[TCP Proxy GO] Error parsing tools/list response JSON from %s: %v. Raw: %s", cmdPath, err, string(responseBytes))
				mu.Lock()
				errors = append(errors, fmt.Sprintf("Server %s invalid response: %v", cmdPath, err))
				mu.Unlock()
				return
			}

			if listResponse.Error != nil {
				log.Printf("[TCP Proxy GO] Server %s returned error for tools/list: %v", cmdPath, listResponse.Error.Message)
				mu.Lock()
				errors = append(errors, fmt.Sprintf("Server %s error: %s", cmdPath, listResponse.Error.Message))
				mu.Unlock()
				return
			}

			// IMPORTANT: Compare the ID from the response with the ID from the *original* request
			if !bytes.Equal(listResponse.ID, req.ID) {
				log.Printf("[TCP Proxy GO] Mismatched ID in tools/list response from %s. Expected: %s, Got: %s", cmdPath, string(req.ID), string(listResponse.ID))
				mu.Lock()
				errors = append(errors, fmt.Sprintf("Server %s mismatched response ID", cmdPath))
				mu.Unlock()
				return
			}

			var resultData struct {
				Tools []map[string]interface{} `json:"tools"`
			}
			if err := json.Unmarshal(listResponse.Result, &resultData); err != nil {
				log.Printf("[TCP Proxy GO] Error parsing 'result' field from tools/list response of %s: %v. Raw Result: %s", cmdPath, err, string(listResponse.Result))
				mu.Lock()
				errors = append(errors, fmt.Sprintf("Server %s invalid result format: %v", cmdPath, err))
				mu.Unlock()
				return
			}

			if len(resultData.Tools) > 0 {
				mu.Lock()
				allTools = append(allTools, resultData.Tools...)
				mu.Unlock()
				log.Printf("[TCP Proxy GO] Got %d tools from %s", len(resultData.Tools), cmdPath)
			} else {
				log.Printf("[TCP Proxy GO] Got 0 tools from %s", cmdPath)
			}
		}(serverCmdPath)
	}

	wg.Wait()

	log.Printf("[TCP Proxy GO] Aggregated %d tools total.", len(allTools))
	if len(errors) > 0 {
		log.Printf("[TCP Proxy GO] Errors encountered during tools/list: %s", strings.Join(errors, "; "))
	}

	// Send the aggregated success response using the original RawMessage ID
	sendSuccessResponse(clientConn, req.ID, map[string]interface{}{"tools": allTools})
}

// Executes a stdio server, handles handshake, sends one request, reads one response.
// requestJson MUST include the trailing newline.
// requestID is the RawMessage ID from the original client request, used for error reporting and response matching.
func executeStdioServer(serverCmdPath, requestJson string, requestID json.RawMessage) ([]byte, error) {
	log.Printf("[TCP Proxy GO] Executing: %s", serverCmdPath)
	cmd := exec.Command(serverCmdPath)
	cmd.Env = os.Environ()

	stdinPipe, err := cmd.StdinPipe()
	if err != nil {
		return nil, fmt.Errorf("error creating stdin pipe for %s: %w", serverCmdPath, err)
	}
	stdoutPipe, err := cmd.StdoutPipe()
	if err != nil {
		stdinPipe.Close()
		return nil, fmt.Errorf("error creating stdout pipe for %s: %w", serverCmdPath, err)
	}
	stderrPipe, err := cmd.StderrPipe()
	if err != nil {
		stdinPipe.Close()
		stdoutPipe.Close()
		return nil, fmt.Errorf("error creating stderr pipe for %s: %w", serverCmdPath, err)
	}

	stdoutReader := bufio.NewReader(stdoutPipe)
	var stderrOutput bytes.Buffer
	processExited := make(chan error, 1)

	// Start the command
	if err := cmd.Start(); err != nil {
		stdinPipe.Close()
		stdoutPipe.Close()
		stderrPipe.Close()
		return nil, fmt.Errorf("error starting command %s: %w", serverCmdPath, err)
	}
	pid := cmd.Process.Pid
	log.Printf("[TCP Proxy GO] Started subprocess PID %d for %s", pid, serverCmdPath)

	// Goroutine to capture stderr
	go func() {
		scanner := bufio.NewScanner(stderrPipe)
		for scanner.Scan() {
			line := scanner.Text()
			log.Printf("[Subprocess %d stderr] %s", pid, line)
			stderrOutput.WriteString(line + "\n")
		}
	}()

	// Goroutine to wait for process exit
	go func() {
		processExited <- cmd.Wait()
	}()

	// --- Communication with Timeout ---
	var finalResponseBytes []byte
	commErrChan := make(chan error, 1) // Channel for communication errors

	go func() { // Goroutine to handle the sequential communication
		defer func() {
			// Ensure stdin is closed if we exit this goroutine,
			// unless it was already closed after sending the request.
			// This helps the subprocess terminate if it's waiting for stdin.
			_ = stdinPipe.Close()
		}()

		// 1. Read initialize response (with timeout)
		var initRespBytes []byte
		var initReadErr error
		readDone := make(chan bool, 1)
		go func() {
			initRespBytes, initReadErr = stdoutReader.ReadBytes('\n')
			readDone <- true
		}()

		select {
		case <-readDone:
			if initReadErr != nil {
				commErrChan <- fmt.Errorf("error reading initialize response from %s (PID %d): %w", serverCmdPath, pid, initReadErr)
				return
			}
			log.Printf("[TCP Proxy GO] Received initialize response from PID %d: %s", pid, strings.TrimSpace(string(initRespBytes)))
			// Initialize response received, proceed with handshake.
		case <-time.After(handshakeTimeout):
			commErrChan <- fmt.Errorf("timeout reading initialize response from %s (PID %d)", serverCmdPath, pid)
			return
		}

		// 2. Send initialized notification
		initNotification := `{"jsonrpc":"2.0","method":"notifications/initialized"}` + "\n"
		if _, err = io.WriteString(stdinPipe, initNotification); err != nil {
			commErrChan <- fmt.Errorf("error writing initialized notification to %s (PID %d): %w", serverCmdPath, pid, err)
			return
		}
		log.Printf("[TCP Proxy GO] Sent initialized notification to PID %d", pid)

		// 3. Send the actual request
		if _, err = io.WriteString(stdinPipe, requestJson); err != nil {
			commErrChan <- fmt.Errorf("error writing request to %s (PID %d): %w", serverCmdPath, pid, err)
			return
		}
		log.Printf("[TCP Proxy GO] Sent request to PID %d: %s", pid, strings.TrimSpace(requestJson))

		// 4. Close stdin now that the request is sent
		// It's important to close stdin so the server knows no more input is coming.
		if err := stdinPipe.Close(); err != nil {
			log.Printf("[TCP Proxy GO] Warning: error closing stdin for PID %d: %v", pid, err)
			// Don't necessarily fail here, the process might still work
		}

		// 5. Read the actual response (with timeout)
		var respReadErr error
		readDone = make(chan bool, 1) // Reset readDone channel
		go func() {
			finalResponseBytes, respReadErr = stdoutReader.ReadBytes('\n')
			readDone <- true
		}()

		select {
		case <-readDone:
			if respReadErr != nil {
				commErrChan <- fmt.Errorf("error reading main response from %s (PID %d): %w", serverCmdPath, pid, respReadErr)
				return
			}
			log.Printf("[TCP Proxy GO] Received main response from PID %d: %s", pid, strings.TrimSpace(string(finalResponseBytes)))
			commErrChan <- nil // Signal success
		case <-time.After(requestTimeout):
			commErrChan <- fmt.Errorf("timeout reading main response from %s (PID %d)", serverCmdPath, pid)
			return
		}
	}()

	// --- Wait for communication or process exit ---
	select {
	case commErr := <-commErrChan:
		if commErr != nil {
			log.Printf("[TCP Proxy GO] Communication error with PID %d: %v", pid, commErr)
			_ = cmd.Process.Kill() // Ensure process is killed on comm error
			// Wait briefly for exit goroutine to potentially capture final stderr/exit code
			select {
			case waitErr := <-processExited:
				log.Printf("[TCP Proxy GO] Process PID %d exited after comm error. Wait error: %v", pid, waitErr)
			case <-time.After(100 * time.Millisecond):
				log.Printf("[TCP Proxy GO] Process PID %d did not exit quickly after comm error.", pid)
			}
			return nil, commErr // Return the communication error
		}
		// Communication successful, now wait for process exit
		select {
		case waitErr := <-processExited:
			if waitErr != nil {
				// Process exited with an error *after* successful communication
				log.Printf("[TCP Proxy GO] Warning: Subprocess PID %d exited with error (%v) after sending response. Stderr: %s", pid, waitErr, stderrOutput.String())
				// Still return the response we received
			} else {
				log.Printf("[TCP Proxy GO] Subprocess PID %d exited successfully after sending response.", pid)
			}
			return finalResponseBytes, nil
		case <-time.After(5 * time.Second): // Timeout waiting for exit after response
			log.Printf("[TCP Proxy GO] Warning: Timeout waiting for process PID %d to exit after successful response.", pid)
			// We got the response, so return it, but the process might linger.
			return finalResponseBytes, nil
		}

	case waitErr := <-processExited:
		// Process exited *before* communication finished or completed with error
		log.Printf("[TCP Proxy GO] Subprocess PID %d exited prematurely. Wait error: %v", pid, waitErr)
		errMsg := fmt.Sprintf("server process %s (PID %d) exited prematurely", serverCmdPath, pid)
		if waitErr != nil {
			errMsg = fmt.Sprintf("%s with error: %v", errMsg, waitErr)
		}
		stderrStr := stderrOutput.String()
		if stderrStr != "" {
			errMsg = fmt.Sprintf("%s. Stderr: %s", errMsg, stderrStr)
		}
		return nil, fmt.Errorf(errMsg)
	}
}

// Helper to send a JSON-RPC error response
func sendErrorResponse(conn net.Conn, id interface{}, code int, message string, data interface{}) {
	var marshaledID json.RawMessage
	if rawID, ok := id.(json.RawMessage); ok {
		marshaledID = rawID // Use original RawMessage if available
	} else {
		// Marshal the interface{} ID (could be nil, string, number)
		if id == nil {
			marshaledID = json.RawMessage("null")
		} else {
			idBytes, err := json.Marshal(id)
			if err != nil {
				log.Printf("[TCP Proxy GO] Error marshalling ID for error response: %v. Using null.", err)
				marshaledID = json.RawMessage("null")
			} else {
				marshaledID = json.RawMessage(idBytes)
			}
		}
	}

	errResp := mcpErrorResponse{
		Jsonrpc: "2.0",
		ID:      marshaledID,
		Error: mcpError{
			Code:    code,
			Message: message,
			Data:    data,
		},
	}
	respBytes, err := json.Marshal(errResp)
	if err != nil {
		log.Printf("[TCP Proxy GO] CRITICAL: Failed to marshal error response: %v", err)
		_, _ = conn.Write([]byte(fmt.Sprintf("{\"jsonrpc\":\"2.0\",\"id\":%s,\"error\":{\"code\":%d,\"message\":\"%s\"}}\n", string(marshaledID), internalErrorCode, "Proxy error marshalling response")))
		return
	}
	_, writeErr := conn.Write(append(respBytes, '\n'))
	if writeErr != nil {
		log.Printf("[TCP Proxy GO] Failed to write error response to client: %v", writeErr)
	}
}

// Helper to send a JSON-RPC success response
func sendSuccessResponse(conn net.Conn, id interface{}, result interface{}) {
	var marshaledID json.RawMessage
	if rawID, ok := id.(json.RawMessage); ok {
		marshaledID = rawID // Use original RawMessage if available
	} else {
		// Marshal the interface{} ID
		idBytes, err := json.Marshal(id)
		if err != nil {
			log.Printf("[TCP Proxy GO] Error marshalling ID for success response: %v. Sending internal error.", err)
			sendErrorResponse(conn, id, internalErrorCode, "Failed to marshal response ID", err.Error())
			return
		}
		marshaledID = json.RawMessage(idBytes)
	}

	resp := mcpSuccessResponse{
		Jsonrpc: "2.0",
		ID:      marshaledID,
		Result:  result,
	}
	respBytes, err := json.Marshal(resp)
	if err != nil {
		log.Printf("[TCP Proxy GO] Error marshalling success response: %v", err)
		sendErrorResponse(conn, marshaledID, internalErrorCode, "Failed to marshal success response", err.Error()) // Send error with marshaled ID
		return
	}
	_, writeErr := conn.Write(append(respBytes, '\n'))
	if writeErr != nil {
		log.Printf("[TCP Proxy GO] Failed to write success response to client: %v", writeErr)
	}
}

// Specific handler for initialize response (mimics basic proxy server)
func sendInitializeResponse(conn net.Conn, id interface{}) {
	capabilities := map[string]interface{}{
		"tools": map[string]interface{}{},
	}
	serverInfo := map[string]string{
		"name":    "mcp-tcp-proxy-go",
		"version": "0.1.0",
	}
	result := map[string]interface{}{
		"protocolVersion": "2024-11-05",
		"capabilities":    capabilities,
		"serverInfo":      serverInfo,
	}
	sendSuccessResponse(conn, id, result)
}
