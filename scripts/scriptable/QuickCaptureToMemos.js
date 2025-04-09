// Variables used by Scriptable.
// These must be at the very top of the file. Do not edit.
// icon-color: blue; icon-glyph: paper-plane;

// Configuration Keys
const KEYCHAIN_URL_KEY = "memos_instance_url";
const KEYCHAIN_TOKEN_KEY = "memos_access_token";
const KEYCHAIN_OPENAI_KEY = "openai_api_key"; // Added for OpenAI

// --- Helper Functions ---

/**
 * Retrieves Memos configuration (URL, Token, OpenAI Key) from Keychain.
 * Prompts the user if configuration is missing.
 * @returns {Promise<{url: string, token: string, openaiApiKey: string|null}>} Configuration object.
 * @throws {Error} If configuration cannot be obtained.
 */
async function getConfig() {
    console.log("Attempting to retrieve configuration from Keychain...");
    let url = Keychain.contains(KEYCHAIN_URL_KEY) ? Keychain.get(KEYCHAIN_URL_KEY) : null;
    let token = Keychain.contains(KEYCHAIN_TOKEN_KEY) ? Keychain.get(KEYCHAIN_TOKEN_KEY) : null;
    let openaiApiKey = Keychain.contains(KEYCHAIN_OPENAI_KEY) ? Keychain.get(KEYCHAIN_OPENAI_KEY) : null;

    // Only prompt if Memos URL or Token is missing. OpenAI key is optional.
    if (!url || !token) {
        console.log("Memos configuration missing or incomplete. Prompting user.");
        // Pass existing values (including potentially null openaiApiKey) to pre-fill/check
        const newConfig = await promptForConfig(url, token, openaiApiKey);
        if (!newConfig || !newConfig.url || !newConfig.token) {
            throw new Error("Memos URL and Token configuration are required to proceed.");
        }
        url = newConfig.url;
        token = newConfig.token;
        openaiApiKey = newConfig.openaiApiKey; // Update openaiApiKey from prompt result
    } else {
        console.log("Configuration retrieved successfully.");
        // Ensure openaiApiKey is null if empty string was somehow stored
        if (openaiApiKey !== null && openaiApiKey.trim() === "") {
            openaiApiKey = null;
            Keychain.remove(KEYCHAIN_OPENAI_KEY); // Clean up empty key
        }
    }

    // Basic validation for URL
    if (url && !url.toLowerCase().startsWith("http")) {
         Keychain.remove(KEYCHAIN_URL_KEY); // Remove invalid URL
         throw new Error(`Invalid URL format stored: ${url}. Please re-run to configure.`);
    }

    // Return all config values, openaiApiKey might be null
    return { url, token, openaiApiKey };
}

/**
 * Prompts the user to enter Memos URL, Access Token, and optionally OpenAI API Key.
 * Saves the entered values to Keychain.
 * @param {string|null} existingUrl - Pre-fill URL if available.
 * @param {string|null} existingToken - Check if token exists (cannot pre-fill secure field).
 * @param {string|null} existingOpenAIKey - Check if OpenAI key exists (used to decide if removing is needed).
 * @returns {Promise<{url: string, token: string, openaiApiKey: string|null}|null>} Configuration object or null if cancelled.
 */
async function promptForConfig(existingUrl, existingToken, existingOpenAIKey) { // Added existingOpenAIKey param
    const alert = new Alert();
    alert.title = "Memos Configuration";
    alert.message = "Enter your Memos instance URL, Access Token (OpenAPI), and optionally your OpenAI API Key.";

    alert.addTextField("Memos URL", existingUrl || "");
    alert.addSecureTextField("Access Token", ""); // Cannot pre-fill secure fields
    // Add field for OpenAI key, don't pre-fill secure field
    alert.addSecureTextField("OpenAI API Key (Optional)", "");

    alert.addAction("Save");
    alert.addCancelAction("Cancel");

    const actionIndex = await alert.presentAlert();

    if (actionIndex === -1) { // Cancelled
        console.log("Configuration prompt cancelled by user.");
        return null;
    }

    const url = alert.textFieldValue(0).trim();
    const token = alert.textFieldValue(1).trim();
    const openaiApiKey = alert.textFieldValue(2).trim(); // Get OpenAI key

    // Basic validation for Memos URL and Token
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

    // Save or remove OpenAI key based on input
    if (openaiApiKey) {
        console.log("Saving OpenAI API Key.");
        Keychain.set(KEYCHAIN_OPENAI_KEY, openaiApiKey);
    } else {
        console.log("No OpenAI API Key provided, removing any existing key.");
        // Only remove if it actually exists to avoid unnecessary Keychain access
        if (Keychain.contains(KEYCHAIN_OPENAI_KEY)) {
            Keychain.remove(KEYCHAIN_OPENAI_KEY);
        }
    }
    console.log("Configuration saved.");

    // Return the potentially null openaiApiKey
    return { url, token, openaiApiKey: openaiApiKey || null };
}

/**
 * Gets text input from Share Sheet, Pasteboard, manual entry, or dictation.
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
      const clipboardAlert = new Alert();
      clipboardAlert.title = "Use Clipboard Content?";
      clipboardAlert.message = `Clipboard contains:\n\n"${clipboardText.substring(
        0,
        100
      )}${clipboardText.length > 100 ? "..." : ""}"`;
      clipboardAlert.addAction("Use Clipboard");
      clipboardAlert.addAction("Other Input"); // Changed from "Enter Manually"
      clipboardAlert.addCancelAction("Cancel");

      const choice = await clipboardAlert.presentAlert();
      if (choice === 0) {
        // Use Clipboard
        console.log("Using text from clipboard.");
        return clipboardText;
      } else if (choice === -1) {
        // Cancelled
        console.log("Input cancelled by user.");
        return null;
      }
      console.log(
        "User chose not to use clipboard text, proceeding to other input options."
      );
    } else {
      console.log("Clipboard is empty or contains no text.");
    }

    // 3. Choose Manual Entry or Dictation
    console.log("Prompting for input method: Manual or Dictation.");
    const inputMethodAlert = new Alert();
    inputMethodAlert.title = "Input Method";
    inputMethodAlert.message = "How would you like to enter the text?";
    inputMethodAlert.addAction("Enter Manually");
    inputMethodAlert.addAction("Use Dictation");
    inputMethodAlert.addCancelAction("Cancel");

    const methodChoice = await inputMethodAlert.presentAlert();

    if (methodChoice === 0) {
      // Enter Manually
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
    } else if (methodChoice === 1) {
      // Use Dictation
      console.log("Starting dictation...");
      try {
        // You can specify locale e.g., Dictation.start("en-US")
        const dictatedText = await Dictation.start();
        const trimmedText = dictatedText?.trim();
        if (!trimmedText) {
          console.log("Dictation resulted in empty text.");
          return null;
        }
        console.log("Using dictated text.");
        return trimmedText;
      } catch (e) {
        console.error(`Dictation failed: ${e}`);
        // Show an error alert to the user
        const dictationErrorAlert = new Alert();
        dictationErrorAlert.title = "Dictation Error";
        dictationErrorAlert.message = `Could not get text from dictation: ${e.message}`;
        dictationErrorAlert.addAction("OK");
        await dictationErrorAlert.presentAlert();
        return null;
      }
    } else {
      // Cancelled input method choice
      console.log("Input method selection cancelled.");
      return null;
    }
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
 * Processes text using OpenAI API for grammar correction and summarization.
 * @param {string} apiKey - The OpenAI API Key.
 * @param {string} text - The text to process.
 * @returns {Promise<string>} The processed text.
 * @throws {Error} If the API request fails or returns an error.
 */
async function processTextWithOpenAI(apiKey, text) {
    console.log("Processing text with OpenAI...");
    const endpoint = 'https://api.openai.com/v1/completions';
    // Simple prompt combining correction and summarization request
    const prompt = `Correct the grammar and spelling of the following text, then provide a concise summary (max 3 sentences):\n\n"${text}"\n\nCorrected and Summarized Text:`;
    const model = 'gpt-3.5-turbo-instruct'; // Or another suitable completions model like 'text-davinci-003' if available/preferred

    const request = new Request(endpoint);
    request.method = 'POST';
    request.headers = {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${apiKey}`
    };
    request.body = JSON.stringify({
        model: model,
        prompt: prompt,
        // Estimate tokens needed: prompt length + text length + buffer for summary/correction + model overhead
        max_tokens: Math.max(150, Math.ceil(text.length * 1.2 + 100)), // Generous buffer
        temperature: 0.5, // Balance creativity and determinism
        n: 1, // We only need one completion
        stop: null // Let the model decide when to stop
    });
    request.timeoutInterval = 60; // Increase timeout for potentially longer AI processing
    request.allowInsecureRequest = false; // Ensure HTTPS

    try {
        console.log(`Sending request to OpenAI (${model})...`);
        // Use loadJSON which handles JSON parsing and throws on non-2xx status codes
        const responseJson = await request.loadJSON();

        // loadJSON already checks for non-2xx status, but we double-check response structure
        if (!responseJson || responseJson.error) {
            const errorMessage = responseJson?.error?.message || 'Unknown OpenAI API error structure';
            console.error("OpenAI API Error in response:", responseJson?.error || responseJson);
            throw new Error(`OpenAI API Error: ${errorMessage}`);
        }

        if (!responseJson.choices || responseJson.choices.length === 0 || !responseJson.choices[0].text) {
            console.error("OpenAI response missing expected choices or text:", responseJson);
            throw new Error('OpenAI response did not contain the expected text.');
        }

        const processedText = responseJson.choices[0].text.trim();
        console.log("OpenAI processing successful. Result length:", processedText.length);
        return processedText;

    } catch (e) {
        console.error(`OpenAI Request Failed: ${e}`);
        let detailedMessage = e.message || 'An unknown error occurred during the OpenAI request.';
        if (request.response && request.response.statusCode) {
            detailedMessage += ` (Status Code: ${request.response.statusCode})`;
        }
        throw new Error(`OpenAI Processing Failed: ${detailedMessage}`);
    }
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
        // Updated message to include OpenAI Key
        confirmAlert.message = "Are you sure you want to remove the saved Memos URL, Access Token, and OpenAI Key?";
        confirmAlert.addAction("Reset");
        confirmAlert.addCancelAction("Cancel");

        const confirmation = await confirmAlert.presentAlert();
        if (confirmation === 0) { // Reset confirmed
            console.log("Removing configuration from Keychain...");
            Keychain.remove(KEYCHAIN_URL_KEY);
            Keychain.remove(KEYCHAIN_TOKEN_KEY);
            // Remove OpenAI key if it exists
            if (Keychain.contains(KEYCHAIN_OPENAI_KEY)) {
                Keychain.remove(KEYCHAIN_OPENAI_KEY);
            }
            console.log("Configuration removed.");

            const successAlert = new Alert();
            successAlert.title = "Configuration Reset";
            // Updated success message
            successAlert.message = "Memos and OpenAI configuration have been removed. Please run the script again to reconfigure.";
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
    let memoId;
    let finalText; // Variable to hold the text to be added as comment

    try {
        // 1. Get Configuration (includes optional openaiApiKey)
        config = await getConfig();
        if (!config) return; // Error handled in getConfig/promptForConfig

        // 2. Get Input Text
        inputText = await getInputText();
        if (!inputText) {
            console.log("No input text provided. Exiting.");
            Script.complete();
            return;
        }

        // --- Optional AI Processing ---
        finalText = inputText; // Default to original text
        // Check if key exists and text is long enough to warrant processing
        const MIN_LENGTH_FOR_AI = 20;
        if (config.openaiApiKey && inputText.trim().length >= MIN_LENGTH_FOR_AI) {
            console.log("OpenAI API Key found and text is non-trivial. Asking user about AI processing.");
            const aiAlert = new Alert();
            aiAlert.title = "AI Processing";
            aiAlert.message = "Process text with AI (Fix Grammar & Summarize)?";
            aiAlert.addAction("Yes, Process");
            aiAlert.addCancelAction("No, Use Original"); // Treat cancel as 'No'

            const aiChoice = await aiAlert.presentAlert();

            if (aiChoice === 0) { // User chose 'Yes'
                console.log("User opted for AI processing. Calling OpenAI...");
                let processingAlert = null; // To dismiss it later
                try {
                    // Show activity indicator while processing
                    processingAlert = new Alert();
                    processingAlert.title = "Processing with AI...";
                    processingAlert.message = "Please wait.";
                    processingAlert.present();

                    const processedResult = await processTextWithOpenAI(config.openaiApiKey, inputText);

                    // Dismiss the indicator *before* showing the next alert
                    if (processingAlert) processingAlert.dismiss();
                    processingAlert = null; // Clear reference

                    console.log("AI processing successful.");

                    // Ask for confirmation of the processed text
                    const confirmProcessedAlert = new Alert();
                    confirmProcessedAlert.title = "AI Processed Text";
                    const previewText = processedResult.length > 300 ? processedResult.substring(0, 297) + "..." : processedResult;
                    confirmProcessedAlert.message = `Use this processed version?\n\n"${previewText}"`;
                    confirmProcessedAlert.addAction("Use Processed Text");
                    confirmProcessedAlert.addAction("Use Original Text"); // Option to revert
                    const confirmChoice = await confirmProcessedAlert.presentAlert();

                    if (confirmChoice === 0) { // User chose 'Use Processed Text'
                        finalText = processedResult;
                        console.log("User confirmed using AI processed text.");
                    } else { // User chose 'Use Original Text' or cancelled confirmation
                        finalText = inputText; // Revert to original
                        console.log("User chose to revert to original text after AI processing.");
                    }

                } catch (aiError) {
                    console.error(`AI Processing Failed: ${aiError}`);
                    // Ensure processing indicator is dismissed if an error occurred
                    if (processingAlert) processingAlert.dismiss();

                    const aiErrorAlert = new Alert();
                    aiErrorAlert.title = "AI Processing Error";
                    // Provide specific error message from the caught error
                    aiErrorAlert.message = `Failed to process text with AI:\n${aiError.message}\n\nUse original text instead?`;
                    aiErrorAlert.addAction("Use Original");
                    aiErrorAlert.addCancelAction("Cancel Script");
                    const errorChoice = await aiErrorAlert.presentAlert();

                    if (errorChoice === -1) { // Cancel Script
                        console.log("Script cancelled due to AI processing error.");
                        Script.complete();
                        return;
                    }
                    // If 'Use Original' is chosen, finalText remains inputText (already default)
                    finalText = inputText; // Explicitly set back just in case
                    console.log("Proceeding with original text after AI error.");
                }
            } else { // User chose 'No' or cancelled the initial AI prompt
                 console.log("User opted out of AI processing or cancelled.");
                 finalText = inputText; // Ensure finalText is original
            }
        } else if (config.openaiApiKey) {
             console.log(`OpenAI key configured, but text length (${inputText.trim().length}) is less than minimum (${MIN_LENGTH_FOR_AI}). Skipping AI processing.`);
             finalText = inputText; // Ensure finalText is original
        } else {
             console.log("No OpenAI API Key configured. Skipping AI processing step.");
             finalText = inputText; // Ensure finalText is original
        }
        // --- End Optional AI Processing ---

        // 3. Create Memo
        // Use a slightly more descriptive title if AI was used? Maybe not necessary.
        const memoTitle = `Quick Capture - ${new Date().toLocaleString()}`;
        createdMemo = await createMemo(config, memoTitle);

        // 4. Extract Memo ID
        if (!createdMemo || !createdMemo.name || !createdMemo.name.includes('/')) {
             console.error("Failed to get valid memo name from creation response.", createdMemo);
             throw new Error("Could not determine the new memo's name/ID.");
        }
        memoId = createdMemo.name.split('/').pop();
         if (!memoId) {
             console.error(`Failed to extract ID from memo name: ${createdMemo.name}`);
             throw new Error(`Invalid memo name format received: ${createdMemo.name}`);
         }
        console.log(`Memo created successfully with ID: ${memoId}`);

        // 5. Add Comment using the final text (original or processed)
        await addCommentToMemo(config, memoId, finalText); // Use finalText here
        console.log("Comment added successfully!");

        // 6. Success Feedback
        // Use args.runsInWidget for checking context, more reliable than config property
        let showAlerts = !(typeof args.runsInWidget === "boolean" && args.runsInWidget);
        if (!showAlerts) {
            console.log("Running in widget context, skipping success alert.");
        }

        if (showAlerts) {
          const successAlert = new Alert();
          successAlert.title = "Success";
          successAlert.message = "Memo and comment added to Memos.";
          // Indicate if AI processing was actually used for the final text
          if (finalText !== inputText) {
              successAlert.message += "\n(Text processed by AI)";
          }
          await successAlert.presentAlert();
        }

    } catch (e) {
        console.error(`Script execution failed: ${e}`);
        // Use args.runsInWidget for checking context
        let showAlerts = !(typeof args.runsInWidget === "boolean" && args.runsInWidget);
         if (!showAlerts) {
            console.log("Running in widget context, skipping error alert.");
        }

        if (showAlerts) {
          const errorAlert = new Alert();
          errorAlert.title = "Error";
          const errorMessage = e.message || "An unknown error occurred.";
          errorAlert.message = `Script failed: ${errorMessage}`;

          // Add specific hints based on error content
          if (e.message) {
              if (e.message.includes("401")) {
                  // Check if it's likely OpenAI or Memos based on message context
                  if (e.message.toLowerCase().includes("openai")) {
                       errorAlert.message += "\n\nCheck if your OpenAI API Key is correct and your account is active.";
                  } else { // Assume Memos otherwise
                       errorAlert.message += "\n\nCheck if your Memos Access Token is correct and has not expired.";
                  }
              } else if (e.message.includes("404") && e.message.toLowerCase().includes("memos")) {
                   errorAlert.message += "\n\nCheck if your Memos URL path is correct.";
              } else if (e.message.includes("ENOTFOUND") || e.message.includes("Could not connect") || e.message.includes("timed out")) {
                  // Could be Memos URL or OpenAI endpoint
                  errorAlert.message += "\n\nCheck your network connection and if the Memos URL/OpenAI service is reachable.";
              } else if (e.message.toLowerCase().includes("openai") && e.message.toLowerCase().includes("quota")) {
                   errorAlert.message += "\n\nCheck your OpenAI account usage/quota.";
              }
          }
          await errorAlert.presentAlert();
        }
    } finally {
        console.log("Script finished.");
        Script.complete();
    }
})();
