// Variables used by Scriptable.
// These must be at the very top of the file. Do not edit.
// icon-color: blue; icon-glyph: paper-plane;

// Configuration Keys
const KEYCHAIN_URL_KEY = "memos_instance_url";
const KEYCHAIN_TOKEN_KEY = "memos_access_token";

// --- Helper Functions ---

/**
 * Retrieves Memos configuration (URL and Token) from Keychain.
 * Prompts the user if configuration is missing.
 * @returns {Promise<{url: string, token: string}>} Configuration object.
 * @throws {Error} If configuration cannot be obtained.
 */
async function getConfig() {
    console.log("Attempting to retrieve configuration from Keychain...");
    let url = Keychain.contains(KEYCHAIN_URL_KEY) ? Keychain.get(KEYCHAIN_URL_KEY) : null;
    let token = Keychain.contains(KEYCHAIN_TOKEN_KEY) ? Keychain.get(KEYCHAIN_TOKEN_KEY) : null;

    if (!url || !token) {
        console.log("Configuration missing or incomplete. Prompting user.");
        const newConfig = await promptForConfig(url, token);
        if (!newConfig || !newConfig.url || !newConfig.token) {
            throw new Error("Configuration is required to proceed.");
        }
        url = newConfig.url;
        token = newConfig.token;
    } else {
        console.log("Configuration retrieved successfully.");
    }
    // Basic validation
    if (!url.toLowerCase().startsWith("http")) {
         Keychain.remove(KEYCHAIN_URL_KEY); // Remove invalid URL
         throw new Error(`Invalid URL format stored: ${url}. Please re-run to configure.`);
    }

    return { url, token };
}

/**
 * Prompts the user to enter Memos URL and Access Token using an Alert.
 * Saves the entered values to Keychain.
 * @param {string|null} existingUrl - Pre-fill URL if available.
 * @param {string|null} existingToken - Check if token exists (cannot pre-fill secure field).
 * @returns {Promise<{url: string, token: string}|null>} Configuration object or null if cancelled.
 */
async function promptForConfig(existingUrl, existingToken) {
    const alert = new Alert();
    alert.title = "Memos Configuration";
    alert.message = "Enter your Memos instance URL (e.g., https://demo.usememos.com) and Access Token (OpenAPI).";

    alert.addTextField("Memos URL", existingUrl || "");
    alert.addSecureTextField("Access Token", ""); // Cannot pre-fill secure fields

    alert.addAction("Save");
    alert.addCancelAction("Cancel");

    const actionIndex = await alert.presentAlert();

    if (actionIndex === -1) { // Cancelled
        console.log("Configuration prompt cancelled by user.");
        return null;
    }

    const url = alert.textFieldValue(0).trim();
    const token = alert.textFieldValue(1).trim();

    // Basic validation
    if (!url || !token) {
        console.error("URL and Token cannot be empty.");
        const errorAlert = new Alert();
        errorAlert.title = "Error";
        errorAlert.message = "Both Memos URL and Access Token are required.";
        await errorAlert.presentAlert();
        return null; // Indicate failure
    }
    if (!url.toLowerCase().startsWith("http")) {
         console.error("Invalid URL format.");
         const errorAlert = new Alert();
         errorAlert.title = "Error";
         errorAlert.message = "Invalid URL format. It should start with http:// or https://";
         await errorAlert.presentAlert();
         return null; // Indicate failure
    }


    console.log("Saving configuration to Keychain...");
    Keychain.set(KEYCHAIN_URL_KEY, url);
    Keychain.set(KEYCHAIN_TOKEN_KEY, token);
    console.log("Configuration saved.");

    return { url, token };
}

/**
 * Gets text input from Share Sheet, Pasteboard, or manual entry.
 * @returns {Promise<string|null>} The input text or null if cancelled/empty.
 */
async function getInputText() {
    console.log("Checking for input source...");
    // 1. Check Share Sheet input (args.plainTexts)
    if (args.plainTexts && args.plainTexts.length > 0) {
        const sharedText = args.plainTexts.join('\n').trim();
        if (sharedText) {
            console.log("Using text from Share Sheet.");
            return sharedText;
        }
    }

    // 2. Check Pasteboard
    const clipboardText = Pasteboard.pasteString()?.trim();
    if (clipboardText) {
        console.log("Found text on clipboard.");
        const alert = new Alert();
        alert.title = "Use Clipboard Content?";
        alert.message = `Clipboard contains:\n\n"${clipboardText.substring(0, 100)}${clipboardText.length > 100 ? '...' : ''}"`;
        alert.addAction("Use Clipboard");
        alert.addCancelAction("Enter Manually"); // Treat cancel as manual entry

        const choice = await alert.presentAlert();
        if (choice === 0) { // Use Clipboard
            console.log("Using text from clipboard.");
            return clipboardText;
        }
         console.log("User chose not to use clipboard text.");
    } else {
         console.log("Clipboard is empty or contains no text.");
    }

    // 3. Prompt Manually
    console.log("Prompting for manual text entry.");
    const manualAlert = new Alert();
    manualAlert.title = "Enter Text for Memo Comment";
    manualAlert.addTextView("", ""); // Use TextView for multi-line input
    manualAlert.addAction("Add");
    manualAlert.addCancelAction("Cancel");

    const manualChoice = await manualAlert.presentAlert();
    if (manualChoice === -1) { // Cancelled
        console.log("Manual input cancelled.");
        return null;
    }

    const manualText = manualAlert.textViewValue(0)?.trim();
     if (!manualText) {
         console.log("No text entered manually.");
         return null;
     }
    console.log("Using manually entered text.");
    return manualText;
}

/**
 * Makes an authenticated request to the Memos API.
 * @param {string} url - The full API endpoint URL.
 * @param {string} method - HTTP method (e.g., "GET", "POST").
 * @param {string} token - The Memos Access Token.
 * @param {object|null} body - The request body object (will be JSON.stringify'd).
 * @returns {Promise<object>} The JSON response from the API.
 * @throws {Error} If the API request fails or returns a non-2xx status code.
 */
async function makeApiRequest(url, method, token, body = null) {
    console.log(`Making API request: ${method} ${url}`);
    const req = new Request(url);
    req.method = method;
    req.headers = {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${token}`
    };
    req.timeoutInterval = 30; // 30 seconds timeout
    req.allowInsecureRequest = false; // Enforce HTTPS unless explicitly http://

    if (body) {
        req.body = JSON.stringify(body);
         console.log(`Request body: ${req.body}`);
    }

    try {
        // Use loadJSON for GET, loadString for POST/PATCH/DELETE to handle potential non-JSON success responses
        let responseData;
        let statusCode;
        let responseText = "";

        if (method.toUpperCase() === "GET") {
             responseData = await req.loadJSON();
             statusCode = req.response.statusCode;
        } else {
             // For POST/etc., load as string first to check for empty responses on success
             responseText = await req.loadString();
             statusCode = req.response.statusCode;
             // Try to parse as JSON if responseText is not empty
             responseData = responseText ? JSON.parse(responseText) : {};
        }


        console.log(`API Response Status Code: ${statusCode}`);
        if (statusCode < 200 || statusCode >= 300) {
            console.error(`API Error Response Text: ${responseText}`);
            throw new Error(`API Error ${statusCode}: ${responseText || 'Unknown error'}`);
        }

        console.log("API request successful.");
        // console.log(`API Response Data: ${JSON.stringify(responseData)}`); // Potentially verbose
        return responseData;

    } catch (e) {
        console.error(`API Request Failed: ${method} ${url} - ${e}`);
        // Check if the error is from JSON parsing or the request itself
        if (e instanceof SyntaxError) {
             throw new Error(`API Error: Failed to parse JSON response. Status: ${req.response?.statusCode}. Response: ${responseText}`);
        } else {
             throw e; // Re-throw original network or status code error
        }
    }
}

/**
 * Creates a new memo in Memos.
 * @param {{url: string, token: string}} config - Memos configuration.
 * @param {string} title - The content/title for the new memo.
 * @returns {Promise<object>} The created memo object from the API.
 * @throws {Error} If memo creation fails.
 */
async function createMemo(config, title) {
    const endpoint = config.url.replace(/\/$/, '') + "/api/v1/memos"; // Ensure no double slash
    const body = {
        content: title,
        visibility: "PRIVATE" // Or make configurable: "PUBLIC", "PROTECTED"
    };
    console.log(`Creating memo with title: "${title}"`);
    return await makeApiRequest(endpoint, "POST", config.token, body);
}

/**
 * Adds a comment to an existing memo.
 * @param {{url: string, token: string}} config - Memos configuration.
 * @param {string} memoIdNumeric - The numeric ID of the memo.
 * @param {string} commentText - The content of the comment.
 * @returns {Promise<object>} The API response for comment creation.
 * @throws {Error} If adding the comment fails.
 */
async function addCommentToMemo(config, memoIdNumeric, commentText) {
    // Endpoint expects the numeric memo ID
    const endpoint = config.url.replace(/\/$/, '') + `/api/v1/memos/${memoIdNumeric}/comments`;
    const body = {
        content: commentText
    };
    console.log(`Adding comment to memo ID: ${memoIdNumeric}`);
    return await makeApiRequest(endpoint, "POST", config.token, body);
}

// --- Main Execution ---

(async () => {
    console.log("Starting Quick Capture to Memos script...");
    let config;
    let inputText;
    let createdMemo;
    let memoIdNumeric;

    try {
        // 1. Get Configuration
        config = await getConfig();
        if (!config) return; // Error handled in getConfig/promptForConfig

        // 2. Get Input Text
        inputText = await getInputText();
        if (!inputText) {
            console.log("No input text provided. Exiting.");
            Script.complete();
            return;
        }

        // 3. Create Memo
        const memoTitle = `Quick Capture - ${new Date().toLocaleString()}`;
        createdMemo = await createMemo(config, memoTitle);

        // 4. Extract Memo ID (numeric part from "memos/123")
        // Adjust based on actual API response structure if needed. Assumes response has a 'name' field.
        if (!createdMemo || !createdMemo.name || !createdMemo.name.includes('/')) {
             console.error("Failed to get valid memo ID from creation response.", createdMemo);
             throw new Error("Could not determine the new memo's ID.");
        }
        memoIdNumeric = createdMemo.name.split('/').pop();
         if (!memoIdNumeric || isNaN(parseInt(memoIdNumeric, 10))) {
             console.error(`Failed to extract numeric ID from memo name: ${createdMemo.name}`);
             throw new Error(`Invalid memo name format received: ${createdMemo.name}`);
         }
        console.log(`Memo created successfully with numeric ID: ${memoIdNumeric}`);

        // 5. Add Comment
        await addCommentToMemo(config, memoIdNumeric, inputText);
        console.log("Comment added successfully!");

        // 6. Success Feedback
        if (!config.runsInWidget) { // Don't show alerts if running in a widget context
            const successAlert = new Alert();
            successAlert.title = "Success";
            successAlert.message = "Memo and comment added to Memos.";
            await successAlert.presentAlert();
        }

    } catch (e) {
        console.error(`Script execution failed: ${e}`);
        // Provide user feedback via Alert, unless running in a widget
        if (!config || !config.runsInWidget) {
            const errorAlert = new Alert();
            errorAlert.title = "Error";
            // Check if e.message is useful, otherwise provide a generic message
            const errorMessage = e.message || "An unknown error occurred.";
            errorAlert.message = `Failed to send to Memos: ${errorMessage}`;
            if (e.message && e.message.includes("401")) {
                 errorAlert.message += "\n\nCheck if your Access Token is correct and has not expired.";
            } else if (e.message && (e.message.includes("ENOTFOUND") || e.message.includes("Could not connect"))) {
                 errorAlert.message += "\n\nCheck if your Memos URL is correct and the server is reachable.";
            }
            await errorAlert.presentAlert();
        }
    } finally {
        console.log("Script finished.");
        Script.complete();
    }
})();