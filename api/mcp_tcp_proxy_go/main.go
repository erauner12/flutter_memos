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
	serverTimeoutCode  = -32001         // Custom code for server timeout
	handshakeTimeout   = 20 * time.Second // Timeout for initialize request/response
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
	_ = json.Unmarshal(req.ID, &reqID) // Attempt to get ID even if parsing failed later

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

	// Execute the stdio server, passing the original request JSON (which includes the newline)
	responseBytes, err := executeStdioServer(serverCmdPath, originalRequestJson+"\n")
	if err != nil {
		log.Printf("[TCP Proxy GO] Error executing stdio server %s for tool '%s': %v", serverCmdPath, toolName, err)
		sendErrorResponse(clientConn, req.ID, internalErrorCode, fmt.Sprintf("Error executing tool '%s'", toolName), err.Error())
		return
	}

	// Validate the response ID matches the request ID before forwarding
	var resp mcpResponse
	if err := json.Unmarshal(responseBytes, &resp); err != nil {
		log.Printf("[TCP Proxy GO] Error parsing response JSON from %s for tool '%s': %v. Raw: %s", serverCmdPath, toolName, err, string(responseBytes))
		sendErrorResponse(clientConn, req.ID, internalErrorCode, fmt.Sprintf("Invalid response from tool '%s'", toolName), nil)
		return
	}
	if !bytes.Equal(resp.ID, req.ID) {
		log.Printf("[TCP Proxy GO] Mismatched ID in response from %s for tool '%s'. Expected: %s, Got: %s", serverCmdPath, toolName, string(req.ID), string(resp.ID))
		sendErrorResponse(clientConn, req.ID, internalErrorCode, fmt.Sprintf("Mismatched response ID from tool '%s'", toolName), nil)
		return
	}


	log.Printf("[TCP Proxy GO] Forwarding response for tool '%s' to client %s", toolName, clientDesc)
	// Add newline back since ReadAll/TrimSpace removed it
	_, writeErr := clientConn.Write(append(responseBytes, '\n'))
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

			// Execute server, passing the specific tools/list request
			responseBytes, err := executeStdioServer(cmdPath, listRequestJson)
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

	// Note: The response from executeStdioServer in the goroutine above
	// is parsed, but the raw bytes aren't directly forwarded here.
	// sendSuccessResponse handles adding the newline.
}

// Executes a stdio server, handles handshake, sends one request, reads one response.
// requestJson MUST include the trailing newline.
func executeStdioServer(serverCmdPath, requestJson string) ([]byte, error) {
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

	// Goroutine to capture and log stderr
	var stderrWg sync.WaitGroup
	stderrWg.Add(1)
	go func() {
		defer stderrWg.Done()
		scanner := bufio.NewScanner(stderrPipe)
		for scanner.Scan() {
			line := scanner.Text()
			log.Printf("[Subprocess %d stderr] %s", pid, line)
			stderrOutput.WriteString(line + "\n")
		}
		if err := scanner.Err(); err != nil {
			log.Printf("[TCP Proxy GO] Error reading stderr from PID %d: %v", pid, err)
		}
		log.Printf("[TCP Proxy GO] Stderr pipe closed for PID %d", pid)
	}()

	// Goroutine to wait for process exit
	go func() {
		processExited <- cmd.Wait()
		close(processExited)
		stderrWg.Wait() // Wait for stderr to finish reading after process exits
	}()

	// --- Communication Goroutine ---
	var finalResponseBytes []byte
	commErrChan := make(chan error, 1)

	go func() {
		var commErr error
		// Ensure stdin is eventually closed when this goroutine exits
		defer func() {
			log.Printf("[TCP Proxy GO] PID %d: Closing stdin in defer.", pid)
			_ = stdinPipe.Close()
			commErrChan <- commErr // Send result (nil or error)
		}()

		// 1. Send initialize request to subprocess
		// Use a unique ID for proxy's internal initialize request
		proxyInitID := fmt.Sprintf("proxy-init-%d", time.Now().UnixNano())
		initRequestBytes, _ := json.Marshal(map[string]interface{}{
			"jsonrpc": "2.0",
			"id":      proxyInitID,
			"method":  "initialize",
			"params": map[string]interface{}{
				"protocolVersion": "2024-11-05", // Announce proxy's supported version
				"clientInfo": map[string]string{
					"name":    "mcp-tcp-proxy-go",
					"version": "0.1.0",
				},
				"capabilities": map[string]interface{}{}, // Proxy doesn't add capabilities
			},
		})
		initRequestJson := string(initRequestBytes) + "\n"
		log.Printf("[TCP Proxy GO] PID %d: Sending initialize request: %s", pid, strings.TrimSpace(initRequestJson))
		if _, err = io.WriteString(stdinPipe, initRequestJson); err != nil {
			commErr = fmt.Errorf("error writing initialize request to %s (PID %d): %w", serverCmdPath, pid, err)
			return
		}

		// 2. Read initialize response from subprocess (with timeout)
		log.Printf("[TCP Proxy GO] PID %d: Attempting to read initialize response...", pid)
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
				commErr = fmt.Errorf("error reading initialize response from %s (PID %d): %w", serverCmdPath, pid, initReadErr)
				return
			}
			log.Printf("[TCP Proxy GO] PID %d: Received initialize response: %s", pid, strings.TrimSpace(string(initRespBytes)))
			// Basic validation: check if it's a valid JSON response for the init ID
			var initResp mcpResponse
			if err := json.Unmarshal(initRespBytes, &initResp); err != nil {
				commErr = fmt.Errorf("error parsing initialize response JSON from %s (PID %d): %w. Raw: %s", serverCmdPath, pid, err, string(initRespBytes))
				return
			}
			var initRespID string
			_ = json.Unmarshal(initResp.ID, &initRespID) // Try to unmarshal ID as string
			if initRespID != proxyInitID {
				commErr = fmt.Errorf("mismatched ID in initialize response from %s (PID %d). Expected: %s, Got: %s", serverCmdPath, pid, proxyInitID, string(initResp.ID))
				return
			}
			if initResp.Error != nil {
				commErr = fmt.Errorf("server %s (PID %d) returned error during initialize: %s", serverCmdPath, pid, initResp.Error.Message)
				return
			}
			log.Printf("[TCP Proxy GO] PID %d: Handshake successful.", pid)
		case <-time.After(handshakeTimeout):
			commErr = fmt.Errorf("timeout reading initialize response from %s (PID %d)", serverCmdPath, pid)
			return
		}

		// 3. Send initialized notification to subprocess
		initNotification := `{"jsonrpc":"2.0","method":"notifications/initialized"}` + "\n"
		log.Printf("[TCP Proxy GO] PID %d: Sending initialized notification...", pid)
		if _, err = io.WriteString(stdinPipe, initNotification); err != nil {
			commErr = fmt.Errorf("error writing initialized notification to %s (PID %d): %w", serverCmdPath, pid, err)
			return
		}
		log.Printf("[TCP Proxy GO] PID %d: Sent initialized notification.", pid)

		// 4. Send the actual client request to subprocess
		log.Printf("[TCP Proxy GO] PID %d: Sending actual request: %s", pid, strings.TrimSpace(requestJson))
		if _, err = io.WriteString(stdinPipe, requestJson); err != nil {
			commErr = fmt.Errorf("error writing actual request to %s (PID %d): %w", serverCmdPath, pid, err)
			return
		}
		log.Printf("[TCP Proxy GO] PID %d: Sent actual request.", pid)

		// Stdin remains open until the communication goroutine exits (handled by defer)

		// 6. Read the final response from subprocess (with timeout)
		log.Printf("[TCP Proxy GO] PID %d: Attempting to read final response until EOF...", pid)
		var respReadErr error
		readDone = make(chan bool, 1)
		var readBytes []byte // Variable to store result of io.ReadAll

		go func() {
			// Read everything until the stdout pipe is closed (EOF)
			readBytes, respReadErr = io.ReadAll(stdoutReader)
			// EOF is expected here, so don't treat it as an error for commErr
			if respReadErr != nil && respReadErr != io.EOF {
				log.Printf("[TCP Proxy GO] PID %d: Error during io.ReadAll: %v", pid, respReadErr)
				// Keep respReadErr to potentially set commErr later
			} else {
				respReadErr = nil // Clear EOF error if that's all it was
			}
			readDone <- true
		}()

		select {
		case <-readDone:
			if respReadErr != nil {
				commErr = fmt.Errorf("error reading final response from %s (PID %d): %w", serverCmdPath, pid, respReadErr)
				return
			}
			// Trim whitespace (like trailing newlines) before assigning
			finalResponseBytes = bytes.TrimSpace(readBytes)
			if len(finalResponseBytes) == 0 {
				// This case might happen if the process exits without writing anything after handshake
				commErr = fmt.Errorf("received empty final response (EOF?) from %s (PID %d)", serverCmdPath, pid)
				return
			}
			log.Printf("[TCP Proxy GO] PID %d: Received final response (ReadAll): %s", pid, string(finalResponseBytes))
			// Success - commErr remains nil
		case <-time.After(requestTimeout):
			commErr = fmt.Errorf("timeout reading final response from %s (PID %d)", serverCmdPath, pid)
			return
		}
	}()

	// --- Wait for communication or process exit ---
	select {
	case commErr := <-commErrChan: // Wait for communication goroutine to finish
		if commErr != nil {
			log.Printf("[TCP Proxy GO] Communication error with PID %d: %v", pid, commErr)
			_ = cmd.Process.Kill()
			waitErr := <-processExited // Wait for exit status
			stderrWg.Wait()           // Ensure all stderr is captured
			return nil, fmt.Errorf("%w. Final Stderr: %s. Exit Status: %v", commErr, stderrOutput.String(), waitErr)
		}
		// Communication successful, wait for process exit
		waitErr := <-processExited
		stderrWg.Wait()
		if waitErr != nil {
			log.Printf("[TCP Proxy GO] Warning: Subprocess PID %d exited with error (%v) after sending response. Stderr: %s", pid, waitErr, stderrOutput.String())
		} else {
			log.Printf("[TCP Proxy GO] Subprocess PID %d exited successfully after sending response.", pid)
		}
		return finalResponseBytes, nil

	case waitErr := <-processExited: // Process exited before communication finished
		stderrWg.Wait()
		log.Printf("[TCP Proxy GO] Subprocess PID %d exited prematurely. Wait error: %v", pid, waitErr)
		errMsg := fmt.Sprintf("server process %s (PID %d) exited prematurely", serverCmdPath, pid)
		if waitErr != nil {
			errMsg = fmt.Sprintf("%s with error: %v", errMsg, waitErr)
		}
		stderrStr := stderrOutput.String()
		if stderrStr != "" {
			errMsg = fmt.Sprintf("%s. Stderr: %s", errMsg, stderrStr)
		}
		// Drain commErrChan in case the comm goroutine eventually sends an error
		go func() { <-commErrChan }()
		return nil, fmt.Errorf(errMsg)
	}
}

// Helper to send a JSON-RPC error response
func sendErrorResponse(conn net.Conn, id interface{}, code int, message string, data interface{}) {
	var marshaledID json.RawMessage
	if rawID, ok := id.(json.RawMessage); ok {
		marshaledID = rawID
	} else {
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
		marshaledID = rawID
	} else {
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
		sendErrorResponse(conn, marshaledID, internalErrorCode, "Failed to marshal success response", err.Error())
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
