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
    manualAlert.addTextField("Comment Text", "");
    manualAlert.addAction("Add");
    manualAlert.addCancelAction("Cancel");

    const manualChoice = await manualAlert.presentAlert();
    if (manualChoice === -1) {
      // Cancelled
      console.log("Manual input cancelled.");
      return null;
    }

    const manualText = manualAlert.textFieldValue(0)?.trim();
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
 * @param {string} memoId - The string ID of the memo (e.g., "aEoUB7vvdhqGRNKAcEkADq").
 * @param {string} commentText - The content of the comment.
 * @returns {Promise<object>} The API response for comment creation.
 * @throws {Error} If adding the comment fails.
 */
async function addCommentToMemo(config, memoId, commentText) {
  // Endpoint expects the string memo ID
  const endpoint =
    config.url.replace(/\/$/, "") + `/api/v1/memos/${memoId}/comments`;
  const body = {
    content: commentText,
  };
  console.log(`Adding comment to memo ID: ${memoId}`);
  return await makeApiRequest(endpoint, "POST", config.token, body);
}

// --- Main Execution ---

(async () => {
    console.log("Starting Quick Capture to Memos script...");

    // --- Configuration Reset Logic ---
    if (args.queryParameters && args.queryParameters.resetConfig === 'true') {
        console.log("Reset configuration argument detected.");
        const confirmAlert = new Alert();
        confirmAlert.title = "Reset Configuration?";
        confirmAlert.message = "Are you sure you want to remove the saved Memos URL and Access Token?";
        confirmAlert.addAction("Reset");
        confirmAlert.addCancelAction("Cancel");

        const confirmation = await confirmAlert.presentAlert();
        if (confirmation === 0) { // Reset confirmed
            console.log("Removing configuration from Keychain...");
            Keychain.remove(KEYCHAIN_URL_KEY);
            Keychain.remove(KEYCHAIN_TOKEN_KEY);
            console.log("Configuration removed.");

            const successAlert = new Alert();
            successAlert.title = "Configuration Reset";
            successAlert.message = "Memos URL and Access Token have been removed. Please run the script again to reconfigure.";
            await successAlert.presentAlert();
            Script.complete();
            return; // Exit script after reset
        } else {
            console.log("Configuration reset cancelled by user.");
            Script.complete();
            return; // Exit script if reset is cancelled
        }
    }
    // --- End Configuration Reset Logic ---

    let config;
    let inputText;
    let createdMemo;
    let memoId; // Changed from memoIdNumeric

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

        // 4. Extract Memo ID (string part from "memos/abc...")
        // Memos v1 uses string IDs, not numeric ones.
        if (!createdMemo || !createdMemo.name || !createdMemo.name.includes('/')) {
             console.error("Failed to get valid memo name from creation response.", createdMemo);
             throw new Error("Could not determine the new memo's name/ID.");
        }
        // Get the part after the last '/' which is the string ID
        memoId = createdMemo.name.split('/').pop();
         if (!memoId) { // Check if memoId is empty after split/pop
             console.error(`Failed to extract ID from memo name: ${createdMemo.name}`);
             throw new Error(`Invalid memo name format received: ${createdMemo.name}`);
         }
        // Removed the isNaN check as the ID is expected to be a string
        console.log(`Memo created successfully with ID: ${memoId}`);

        // 5. Add Comment using the string memoId
        await addCommentToMemo(config, memoId, inputText);
        console.log("Comment added successfully!");

        // 6. Success Feedback
        // Check if config exists and runsInWidget property is available and false
        let showAlerts = true; // Default to showing alerts
        if (typeof config.runsInWidget === "boolean") {
          showAlerts = !config.runsInWidget;
        } else {
          console.log(
            "runsInWidget property not found or not boolean, assuming not in widget."
          );
        }

        if (showAlerts) {
          const successAlert = new Alert();
          successAlert.title = "Success";
          successAlert.message = "Memo and comment added to Memos.";
          await successAlert.presentAlert();
        } else {
          console.log(
            "Running in widget context or config missing, skipping success alert."
          );
        }

    } catch (e) {
        console.error(`Script execution failed: ${e}`);
        // Provide user feedback via Alert, unless running in a widget
        let showAlerts = true; // Default to showing alerts
        if (config && typeof config.runsInWidget === "boolean") {
          showAlerts = !config.runsInWidget;
        } else {
          console.log(
            "runsInWidget property not found or not boolean, assuming not in widget for error."
          );
        }

        if (showAlerts) {
          const errorAlert = new Alert();
          errorAlert.title = "Error";
          const errorMessage = e.message || "An unknown error occurred.";
          errorAlert.message = `Failed to send to Memos: ${errorMessage}`;
          if (e.message && e.message.includes("401")) {
            errorAlert.message +=
              "\n\nCheck if your Access Token is correct and has not expired.";
          } else if (
            e.message &&
            (e.message.includes("ENOTFOUND") ||
              e.message.includes("Could not connect"))
          ) {
            errorAlert.message +=
              "\n\nCheck if your Memos URL is correct and the server is reachable.";
          }
          await errorAlert.presentAlert();
        } else {
          console.log(
            "Running in widget context or config missing, skipping error alert."
          );
        }
    } finally {
        console.log("Script finished.");
        Script.complete();
    }
})();