// Variables used by Scriptable.
// These must be at the very top of the file. Do not edit.
// icon-color: blue; icon-glyph: paper-plane;

// Configuration Keys
const KEYCHAIN_URL_KEY = "memos_instance_url";
const KEYCHAIN_TOKEN_KEY = "memos_access_token";
const KEYCHAIN_OPENAI_KEY = "openai_api_key"; // Added for OpenAI

// --- Helper Functions ---

/**
 * Presents an HTML form in a WebView and waits for submission.
 * The HTML should contain JavaScript that calls `completion(result)`
 * where `result` is the data to be returned (e.g., a JSON object).
 * @param {string} htmlContent - The HTML string to display.
 * @param {boolean} [fullscreen=false] - Whether to present fullscreen.
 * @param {Size} [preferredSize=null] - Preferred size for Shortcuts/Siri.
 * @returns {Promise<any|null>} The data passed to the completion() function from JS, or null if dismissed.
 * @throws {Error} If WebView presentation or JS evaluation fails unexpectedly.
 */
/**
 * Presents an HTML form in a WebView and waits for submission or dismissal.
 * The HTML should contain JavaScript that calls `completion(result)`
 * where `result` is the data to be returned (e.g., a JSON object).
 * @param {string} htmlContent - The HTML string to display.
 * @param {boolean} [fullscreen=false] - Whether to present fullscreen.
 * @param {Size} [preferredSize=null] - Preferred size (currently unused but kept for potential future use).
 * @returns {Promise<any|null>} The data passed to the completion() function from JS, or null if dismissed manually or on error.
 */
async function presentWebViewForm(
  htmlContent,
  fullscreen = false,
  preferredSize = null // Parameter kept, though not used in current logic
) {
  console.log("Configuring WebView form...");
  const wv = new WebView();
  // Optional: Set up shouldAllowRequest if needed

  try {
    // 1. Load the HTML content first
    console.log("Loading HTML into WebView instance...");
    await wv.loadHTML(htmlContent);
    console.log("HTML loaded.");

    // 2. Start evaluateJavaScript listener (waits for completion() call)
    console.log("Setting up JavaScript listener (evaluateJavaScript)...");
    const evaluatePromise = wv.evaluateJavaScript(
      `
            // Scriptable implicitly defines 'completion(result)' when useCallback is true.
            // We just need to ensure our HTML's JS calls it.

            // Check if the initialization function exists in the HTML and call it
            if (typeof initializeForm === 'function') {
                console.log("Calling initializeForm() from evaluateJavaScript.");
                initializeForm(); // Sets up the form's submit listener etc.
            } else {
                console.error("initializeForm function not found in HTML script.");
                // If init fails, call completion with an error to unblock the script
                if (typeof completion === 'function') {
                   completion({ error: "Initialization function missing in HTML" });
                } else {
                   // Should not happen if useCallback is true, but log just in case
                   console.error("CRITICAL: completion function not available during init check.");
                }
            }
            console.log("JavaScript listener setup complete. Waiting for user interaction or dismissal...");
            // No explicit return value needed here; Scriptable waits for completion().
            `,
      true // useCallback = true: Waits for completion()
    );

    // 3. Create a promise that handles presentation and manual dismissal
    console.log(`Preparing to present WebView (fullscreen: ${fullscreen})...`);
    const presentPromise = new Promise((resolve, reject) => {
      // present() returns a promise that resolves when the view is dismissed.
      wv.present(fullscreen)
        .then(() => {
          // This 'then' block executes *only* when the WebView is dismissed by the user
          // or potentially by Scriptable closing it after completion().
          // We use it to detect *manual* dismissal before completion() is called.
          // If completion() was called, evaluatePromise would have already resolved.
          console.log("WebView dismissal detected by present().then().");
          // Reject this promise to signal manual dismissal in Promise.race
          reject(new Error("WebView dismissed manually"));
        })
        .catch(reject); // Catch potential errors during presentation itself
    });

    // 4. Wait for the first promise to settle
    console.log(
      "Waiting for form submission (completion()) or manual dismissal..."
    );
    const result = await Promise.race([evaluatePromise, presentPromise]);

    // If we get here, evaluatePromise resolved successfully before dismissal
    console.log("Form submitted via completion(). Result:", result);
    // It seems Scriptable automatically dismisses the WebView when completion() is called
    // if it was presented via an instance's present() method.
    return result;
  } catch (e) {
    // This catch block handles errors from loadHTML, evaluateJavaScript setup,
    // presentation errors, or the rejection from presentPromise (manual dismissal).
    if (e.message === "WebView dismissed manually") {
      console.log("WebView was dismissed manually by the user.");
      return null; // Return null specifically for manual dismissal
    } else {
      // Log other types of errors
      console.error(`Error during WebView operation: ${e}`);
      // Optionally show an alert for unexpected errors
      // let alert = new Alert();
      // alert.title = "WebView Error";
      // alert.message = \`An unexpected error occurred: \${e.message}\`;
      // await alert.present();
      return null; // Return null for other errors as well for consistency
    }
  }
}

/**
 * Basic HTML escaping function.
 * @param {string} unsafe - The string to escape.
 * @returns {string} Escaped string.
 */
function escapeHtml(unsafe) {
  if (typeof unsafe !== "string") return "";
  return unsafe
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

/**
 * Generates HTML for the Memos configuration form.
 * @param {string|null} existingUrl - Pre-fill URL if available.
 * @returns {string} HTML content for the configuration form.
 */
function generateConfigFormHtml(existingUrl) {
  // Basic CSS for better appearance
  const css = `
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; padding: 15px; background-color: #f8f8f8; color: #333; }
        label { display: block; margin-bottom: 5px; font-weight: bold; }
        input[type=text], input[type=password] { width: 95%; padding: 10px; margin-bottom: 15px; border: 1px solid #ccc; border-radius: 5px; font-size: 16px; }
        button { padding: 12px 20px; background-color: #007aff; color: white; border: none; border-radius: 8px; cursor: pointer; font-size: 16px; width: 100%; margin-top: 10px; }
        button:hover { background-color: #0056b3; }
        .error { color: red; font-size: 0.9em; margin-top: -10px; margin-bottom: 10px; }
        h2 { margin-top: 0; color: #111; }
        p { color: #555; }
    `;

  // Pre-fill URL if provided
  const urlValue = existingUrl ? `value="${escapeHtml(existingUrl)}"` : "";

  return `
    <!DOCTYPE html>
    <html>
    <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Memos Configuration</title>
        <style>${css}</style>
    </head>
    <body>
        <h2>Memos Configuration</h2>
        <p>Enter your Memos instance URL, Access Token (OpenAPI), and optionally your OpenAI API Key.</p>
        <form id="configForm">
            <label for="memosUrl">Memos URL:</label>
            <input type="text" id="memosUrl" name="memosUrl" ${urlValue} required placeholder="https://your-memos.com">
            <div id="urlError" class="error" style="display: none;"></div>

            <label for="accessToken">Access Token:</label>
            <input type="password" id="accessToken" name="accessToken" required placeholder="Enter Memos Token">
            <div id="tokenError" class="error" style="display: none;"></div>

            <label for="openaiKey">OpenAI API Key (Optional):</label>
            <input type="password" id="openaiKey" name="openaiKey" placeholder="Enter OpenAI Key (Optional)">

            <button type="submit">Save Configuration</button>
        </form>

        <script>
        // Wrap setup logic in a function
        function initializeForm() {
            try { // Add try block
                const form = document.getElementById('configForm');
                const urlInput = document.getElementById('memosUrl');
                const tokenInput = document.getElementById('accessToken');
                const openaiInput = document.getElementById('openaiKey');
                const urlError = document.getElementById('urlError');
                const tokenError = document.getElementById('tokenError');

                if (!form || !urlInput || !tokenInput || !openaiInput || !urlError || !tokenError) {
                    console.error("Config form elements not found during initialization.");
                    alert("Error initializing config form elements.");
                    if (typeof completion === 'function') completion({ error: "Initialization failed: Elements missing" });
                    return;
                }

                form.addEventListener('submit', (event) => {
                    event.preventDefault(); // Prevent default form submission
                    urlError.style.display = 'none';
                    tokenError.style.display = 'none';
                    let isValid = true;

                    const url = urlInput.value.trim();
                    const token = tokenInput.value.trim();
                    const openaiApiKey = openaiInput.value.trim();

                    if (!url) {
                        urlError.textContent = 'Memos URL is required.';
                        urlError.style.display = 'block';
                        isValid = false;
                    } else if (!url.toLowerCase().startsWith('http://') && !url.toLowerCase().startsWith('https://')) {
                        urlError.textContent = 'URL must start with http:// or https://';
                        urlError.style.display = 'block';
                        isValid = false;
                    }

                    if (!token) {
                        tokenError.textContent = 'Access Token is required.';
                        tokenError.style.display = 'block';
                        isValid = false;
                    }

                    if (isValid) {
                        // Call the completion function provided by Scriptable's evaluateJavaScript
                        if (typeof completion === 'function') {
                            completion({
                                url: url,
                                token: token,
                                openaiApiKey: openaiApiKey || null // Return null if empty
                            });
                        } else {
                            console.error('CRITICAL: completion function unexpectedly not available!');
                            alert('Error: Cannot submit config form due to internal issue.');
                        }
                    }
                });
                console.log("Config form initialized.");
            } catch (initError) { // Add catch block
                console.error("Error during config form initialization:", initError);
                alert("A critical error occurred setting up the configuration form.");
                // Call completion with an error object if possible
                if (typeof completion === 'function') completion({ error: "Initialization crashed", details: initError.message });
            }
        }
         // Do NOT call initializeForm() here directly anymore.
    </script>
</body>
</html>
`;
}

/**
 * Generates HTML for the main text input form.
 * @param {string} [prefillText=''] - Text to pre-fill the textarea.
 * @param {boolean} [showAiOption=false] - Whether to show the AI processing checkbox.
 * @returns {string} HTML content for the input form.
 */
function generateInputFormHtml(prefillText = "", showAiOption = false) {
  const css = `
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; padding: 15px; display: flex; flex-direction: column; height: 95vh; background-color: #f8f8f8; color: #333; }
        textarea { flex-grow: 1; width: 95%; padding: 10px; margin-bottom: 15px; border: 1px solid #ccc; border-radius: 8px; font-size: 16px; resize: none; }
        button { padding: 12px 20px; background-color: #007aff; color: white; border: none; border-radius: 8px; cursor: pointer; font-size: 16px; width: 100%; margin-top: auto; }
        button:hover { background-color: #0056b3; }
        .options { margin-bottom: 15px; display: flex; align-items: center; }
        label[for=useAi] { margin-left: 8px; font-weight: normal; }
        input[type=checkbox] { width: 18px; height: 18px; }
        h2 { margin-top: 0; color: #111; }
        .clipboard-notice { font-size: 0.9em; color: #666; margin-bottom: 10px; }
        form { display: flex; flex-direction: column; flex-grow: 1; }
    `;

  const clipboardNotice = prefillText
    ? '<div class="clipboard-notice">Text pre-filled from clipboard.</div>'
    : "";
  const aiCheckboxHtml = showAiOption
    ? `
        <div class="options">
            <input type="checkbox" id="useAi" name="useAi">
            <label for="useAi">Process with AI (Fix Grammar & Summarize)</label>
        </div>
    `
    : "";

  return `
    <!DOCTYPE html>
    <html>
    <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <title>Enter Memo Content</title>
        <style>${css}</style>
    </head>
    <body>
        <h2>Enter Memo Content</h2>
        ${clipboardNotice}
        <form id="inputForm">
            <textarea id="memoContent" name="memoContent" placeholder="Type or paste your memo content here... (Use keyboard dictation if needed)" required>${prefillText}</textarea>
            ${aiCheckboxHtml}
            <button type="submit">Add Memo</button>
        </form>

        <script>
            // Wrap setup logic in a function to be called by evaluateJavaScript
            function initializeForm() {
                try { // Add try block
                    const form = document.getElementById('inputForm');
                    const contentInput = document.getElementById('memoContent');
                    const useAiCheckbox = document.getElementById('useAi'); // Might be null

                    if (!form || !contentInput) {
                        console.error("Form or content input not found during initialization.");
                        alert("Error initializing form elements.");
                        if (typeof completion === 'function') completion({ error: "Initialization failed: Elements missing" });
                        return;
                    }

                    form.addEventListener('submit', (event) => {
                        event.preventDefault();
                        const content = contentInput.value.trim();
                        const processWithAi = useAiCheckbox ? useAiCheckbox.checked : false;

                        if (content) {
                             // completion is guaranteed to exist here because initializeForm
                             // is called *after* completion is defined by evaluateJavaScript
                             if (typeof completion === 'function') {
                                completion({
                                    text: content,
                                    useAi: processWithAi
                                });
                            } else {
                                 // This case should ideally not happen now
                                 console.error('CRITICAL: completion function unexpectedly not available!');
                                 alert('Error: Cannot submit form due to internal issue.');
                            }
                        } else {
                            alert("Please enter some content for the memo.");
                        }
                    });

                     // Auto-focus the text area
                     contentInput.focus();
                     console.log("Input form initialized and focused.");
                } catch (initError) { // Add catch block
                    console.error("Error during input form initialization:", initError);
                    alert("A critical error occurred setting up the input form.");
                     // Call completion with an error object if possible
                    if (typeof completion === 'function') completion({ error: "Initialization crashed", details: initError.message });
                }
            }

             // Do NOT call initializeForm() here directly anymore.
             // It will be called by the evaluateJavaScript in presentWebViewForm.
        </script>
    </body>
    </html>
    `;
}

/**
 * Generates HTML to confirm using AI-processed text.
 * @param {string} originalText - The original input text.
 * @param {string} processedText - The text after AI processing.
 * @returns {string} HTML content for the AI confirmation view.
 */
function generateAiConfirmHtml(originalText, processedText) {
  const css = `
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; padding: 15px; background-color: #f8f8f8; color: #333; }
        .text-container { border: 1px solid #ccc; border-radius: 8px; padding: 10px; margin-bottom: 15px; background-color: white; max-height: 200px; overflow-y: auto; white-space: pre-wrap; font-size: 14px; }
        button { padding: 12px 15px; background-color: #007aff; color: white; border: none; border-radius: 8px; cursor: pointer; font-size: 16px; margin-right: 10px; margin-top: 10px; }
        button.secondary { background-color: #6c757d; }
        button:hover { opacity: 0.8; }
        h2, h3 { margin-top: 0; color: #111; }
        h3 { margin-bottom: 5px; }
        p { color: #555; }
        .button-group { margin-top: 15px; }
    `;

  const escapedProcessed = escapeHtml(processedText);
  const escapedOriginal = escapeHtml(originalText);

  return `
    <!DOCTYPE html>
    <html>
    <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Confirm AI Text</title>
        <style>${css}</style>
    </head>
    <body>
        <h2>AI Processed Text</h2>
        <p>Review the AI-processed text below. Choose which version to use for the memo comment.</p>

        <h3>Processed Text:</h3>
        <div class="text-container">${escapedProcessed}</div>

        <h3>Original Text:</h3>
        <div class="text-container">${escapedOriginal}</div>

        <div class="button-group">
            <button id="useProcessed">Use Processed Text</button>
            <button id="useOriginal" class="secondary">Use Original Text</button>
        </div>

        <script>
            // Wrap setup logic in a function
            function initializeForm() {
                try { // Add try block
                    const useProcessedButton = document.getElementById('useProcessed');
                    const useOriginalButton = document.getElementById('useOriginal');

                    if (!useProcessedButton || !useOriginalButton) {
                         console.error("AI confirm form elements not found during initialization.");
                         alert("Error initializing AI confirm form elements.");
                         if (typeof completion === 'function') completion({ error: "Initialization failed: Elements missing" });
                         return;
                    }

                    useProcessedButton.addEventListener('click', () => {
                         if (typeof completion === 'function') {
                            completion({ useProcessed: true });
                         } else { console.error('CRITICAL: completion function unexpectedly not available!'); alert('Error submitting choice.'); }
                    });

                    useOriginalButton.addEventListener('click', () => {
                         if (typeof completion === 'function') {
                            completion({ useProcessed: false });
                         } else { console.error('CRITICAL: completion function unexpectedly not available!'); alert('Error submitting choice.'); }
                    });
                    console.log("AI Confirm form initialized.");
                } catch (initError) { // Add catch block
                    console.error("Error during AI confirm form initialization:", initError);
                    alert("A critical error occurred setting up the AI confirmation form.");
                     // Call completion with an error object if possible
                    if (typeof completion === 'function') completion({ error: "Initialization crashed", details: initError.message });
                }
            }
                 // Do NOT call initializeForm() here directly anymore.
        </script>
    </body>
    </html>
    `;
}

/**
 * Retrieves Memos configuration (URL, Token, OpenAI Key) from Keychain.
 * Prompts the user using a WebView form if configuration is missing.
 * @returns {Promise<{url: string, token: string, openaiApiKey: string|null}|null>} Configuration object, or null if cancelled/failed.
 * @throws {Error} If configuration cannot be obtained and user cancels/fails prompt.
 */
async function getConfig() {
  console.log("Attempting to retrieve configuration from Keychain...");
  let url = Keychain.contains(KEYCHAIN_URL_KEY)
    ? Keychain.get(KEYCHAIN_URL_KEY)
    : null;
  let token = Keychain.contains(KEYCHAIN_TOKEN_KEY)
    ? Keychain.get(KEYCHAIN_TOKEN_KEY)
    : null;
  let openaiApiKey = Keychain.contains(KEYCHAIN_OPENAI_KEY)
    ? Keychain.get(KEYCHAIN_OPENAI_KEY)
    : null;

  // Basic validation for stored URL before proceeding
  if (url && !url.toLowerCase().startsWith("http")) {
    console.warn(`Invalid URL format stored: ${url}. Clearing and prompting.`);
    Keychain.remove(KEYCHAIN_URL_KEY);
    url = null;
  }
  // Clean up potentially empty stored OpenAI key
  if (openaiApiKey !== null && openaiApiKey.trim() === "") {
    openaiApiKey = null;
    if (Keychain.contains(KEYCHAIN_OPENAI_KEY)) {
      Keychain.remove(KEYCHAIN_OPENAI_KEY);
    }
  }

  // Prompt if Memos URL or Token is missing.
  if (!url || !token) {
    console.log(
      "Memos configuration missing or incomplete. Prompting user via WebView."
    );
    const configHtml = generateConfigFormHtml(url);
    const formData = await presentWebViewForm(configHtml, false);

    if (!formData || !formData.url || !formData.token) {
      console.log(
        "Configuration prompt cancelled or failed (WebView returned null or incomplete data)."
      );
      throw new Error(
        "Configuration cancelled or failed. Memos URL and Token are required."
      );
    }

    url = formData.url;
    token = formData.token;
    openaiApiKey = formData.openaiApiKey;

    console.log("Saving configuration to Keychain...");
    Keychain.set(KEYCHAIN_URL_KEY, url);
    Keychain.set(KEYCHAIN_TOKEN_KEY, token);

    if (openaiApiKey) {
      console.log("Saving OpenAI API Key.");
      Keychain.set(KEYCHAIN_OPENAI_KEY, openaiApiKey);
    } else {
      console.log("No OpenAI API Key provided, removing any existing key.");
      if (Keychain.contains(KEYCHAIN_OPENAI_KEY)) {
        Keychain.remove(KEYCHAIN_OPENAI_KEY);
      }
    }
    console.log("Configuration saved.");
  } else {
    console.log("Configuration retrieved successfully from Keychain.");
  }

  return { url, token, openaiApiKey };
}

// REMOVED the old promptForConfig function

/**
 * Gets text input from Share Sheet, Pasteboard, or WebView form.
 * @param {boolean} allowAiOption - Whether to include the AI processing option in the form.
 * @returns {Promise<{text: string, useAi: boolean}|null>} Object with input text and AI choice, or null if cancelled/empty.
 */
async function getInputText(allowAiOption = false) {
  // Added allowAiOption parameter
  console.log("Checking for input source...");
  let initialText = "";

  // 1. Check Share Sheet input (args.plainTexts)
  if (args.plainTexts && args.plainTexts.length > 0) {
    const sharedText = args.plainTexts.join("\n").trim();
    if (sharedText) {
      console.log("Using text from Share Sheet.");
      initialText = sharedText;
      // Proceed directly to WebView form with this text
    }
  }

  // 2. Check Pasteboard (only if Share Sheet didn't provide text)
  if (!initialText) {
    const clipboardText = Pasteboard.pasteString()?.trim();
    if (clipboardText) {
      console.log("Found text on clipboard. Will pre-fill form.");
      initialText = clipboardText;
      // Note: We removed the alert asking *if* they want to use clipboard.
      // We now pre-fill the form and let them edit/clear it.
    } else {
      console.log("Clipboard is empty or contains no text.");
    }
  }

  // 3. Present WebView form for input (manual entry or editing pre-filled text)
  // Dictation is handled by the keyboard's mic button within the text area.
  console.log("Presenting WebView form for text input.");
  const inputHtml = generateInputFormHtml(initialText, allowAiOption);
  // Present non-fullscreen by default, adjust if needed
  const formData = await presentWebViewForm(inputHtml, false);

  // Check if the form was cancelled (returned null) or didn't return expected data
  if (
    !formData ||
    typeof formData.text === "undefined" ||
    typeof formData.useAi === "undefined"
  ) {
    console.log("Input cancelled or form did not return expected data.");
    return null;
  }
  // Also check if text is empty after trimming
  if (formData.text.trim() === "") {
    console.log("No text entered.");
    return null;
  }

  console.log(`Input received. Use AI: ${formData.useAi}`);
  return { text: formData.text.trim(), useAi: formData.useAi }; // Return object with trimmed text
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
    Authorization: `Bearer ${token}`,
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
      throw new Error(
        `API Error ${statusCode}: ${responseText || "Unknown error"}`
      );
    }

    console.log("API request successful.");
    // console.log(`API Response Data: ${JSON.stringify(responseData)}`); // Potentially verbose
    return responseData;
  } catch (e) {
    console.error(`API Request Failed: ${method} ${url} - ${e}`);
    // Check if the error is from JSON parsing or the request itself
    if (e instanceof SyntaxError) {
      throw new Error(
        `API Error: Failed to parse JSON response. Status: ${req.response?.statusCode}. Response: ${responseText}`
      );
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
  const endpoint = config.url.replace(/\/$/, "") + "/api/v1/memos"; // Ensure no double slash
  const body = {
    content: title,
    visibility: "PRIVATE", // Or make configurable: "PUBLIC", "PROTECTED"
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
  const endpoint = "https://api.openai.com/v1/completions";
  // Simple prompt combining correction and summarization request
  const prompt = `Correct the grammar and spelling of the following text, then provide a concise summary (max 3 sentences):\n\n"${text}"\n\nCorrected and Summarized Text:`;
  const model = "gpt-3.5-turbo-instruct"; // Or another suitable completions model like 'text-davinci-003' if available/preferred

  const request = new Request(endpoint);
  request.method = "POST";
  request.headers = {
    "Content-Type": "application/json",
    Authorization: `Bearer ${apiKey}`,
  };
  request.body = JSON.stringify({
    model: model,
    prompt: prompt,
    // Estimate tokens needed: prompt length + text length + buffer for summary/correction + model overhead
    max_tokens: Math.max(150, Math.ceil(text.length * 1.2 + 100)), // Generous buffer
    temperature: 0.5, // Balance creativity and determinism
    n: 1, // We only need one completion
    stop: null, // Let the model decide when to stop
  });
  request.timeoutInterval = 60; // Increase timeout for potentially longer AI processing
  request.allowInsecureRequest = false; // Ensure HTTPS

  try {
    console.log(`Sending request to OpenAI (${model})...`);
    // Use loadJSON which handles JSON parsing and throws on non-2xx status codes
    const responseJson = await request.loadJSON();

    // loadJSON already checks for non-2xx status, but we double-check response structure
    if (!responseJson || responseJson.error) {
      const errorMessage =
        responseJson?.error?.message || "Unknown OpenAI API error structure";
      console.error(
        "OpenAI API Error in response:",
        responseJson?.error || responseJson
      );
      throw new Error(`OpenAI API Error: ${errorMessage}`);
    }

    if (
      !responseJson.choices ||
      responseJson.choices.length === 0 ||
      !responseJson.choices[0].text
    ) {
      console.error(
        "OpenAI response missing expected choices or text:",
        responseJson
      );
      throw new Error("OpenAI response did not contain the expected text.");
    }

    const processedText = responseJson.choices[0].text.trim();
    console.log(
      "OpenAI processing successful. Result length:",
      processedText.length
    );
    return processedText;
  } catch (e) {
    console.error(`OpenAI Request Failed: ${e}`);
    let detailedMessage =
      e.message || "An unknown error occurred during the OpenAI request.";
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
  if (args.queryParameters && args.queryParameters.resetConfig === "true") {
    console.log("Reset configuration argument detected.");
    const confirmAlert = new Alert();
    confirmAlert.title = "Reset Configuration?";
    confirmAlert.message =
      "Are you sure you want to remove the saved Memos URL, Access Token, and OpenAI Key?";
    confirmAlert.addAction("Reset");
    confirmAlert.addCancelAction("Cancel");

    const confirmation = await confirmAlert.presentAlert();
    if (confirmation === 0) {
      console.log("Removing configuration from Keychain...");
      Keychain.remove(KEYCHAIN_URL_KEY);
      Keychain.remove(KEYCHAIN_TOKEN_KEY);
      if (Keychain.contains(KEYCHAIN_OPENAI_KEY)) {
        Keychain.remove(KEYCHAIN_OPENAI_KEY);
      }
      console.log("Configuration removed.");

      const successAlert = new Alert();
      successAlert.title = "Configuration Reset";
      successAlert.message =
        "Memos and OpenAI configuration have been removed. Please run the script again to reconfigure.";
      await successAlert.presentAlert();
      Script.complete();
      return;
    } else {
      console.log("Configuration reset cancelled by user.");
      Script.complete();
      return;
    }
  }
  // --- End Configuration Reset Logic ---

  let config;
  let inputData;
  let createdMemo;
  let memoId;
  let finalText;
  let originalInputText;

  try {
    config = await getConfig();

    const canShowAiOption = !!config.openaiApiKey;
    inputData = await getInputText(canShowAiOption);

    if (!inputData) {
      console.log("No input text provided or cancelled. Exiting.");
      Script.complete();
      return;
    }

    originalInputText = inputData.text;
    let processWithAi = inputData.useAi;
    finalText = originalInputText;

    const MIN_LENGTH_FOR_AI = 20;

    if (
      processWithAi &&
      config.openaiApiKey &&
      originalInputText.trim().length >= MIN_LENGTH_FOR_AI
    ) {
      console.log("User opted for AI processing via form. Calling OpenAI...");
      let processingAlert = null;

      try {
        processingAlert = new Alert();
        processingAlert.title = "Processing with AI...";
        processingAlert.message = "Please wait.";
        processingAlert.present();

        const processedResult = await processTextWithOpenAI(
          config.openaiApiKey,
          originalInputText
        );

        if (processingAlert && typeof processingAlert.dismiss === "function") {
          try {
            processingAlert.dismiss();
          } catch (dismissError) {
            console.warn("Could not dismiss processing alert:", dismissError);
          }
        }
        processingAlert = null;

        console.log(
          "AI processing successful. Asking for confirmation via WebView."
        );
        const confirmHtml = generateAiConfirmHtml(
          originalInputText,
          processedResult
        );
        const confirmData = await presentWebViewForm(confirmHtml, false);

        if (confirmData && confirmData.useProcessed === true) {
          finalText = processedResult;
          console.log("User confirmed using AI processed text via WebView.");
        } else {
          finalText = originalInputText;
          console.log(
            "User chose to revert to original text or cancelled confirmation (via WebView)."
          );
        }
      } catch (aiError) {
        console.error(`AI Processing Failed: ${aiError}`);
        if (processingAlert && typeof processingAlert.dismiss === "function") {
          try {
            processingAlert.dismiss();
          } catch (dismissError) {
            console.warn("Could not dismiss processing alert:", dismissError);
          }
        }

        const aiErrorAlert = new Alert();
        aiErrorAlert.title = "AI Processing Error";
        aiErrorAlert.message = `Failed to process text with AI:\n${aiError.message}\n\nUse original text instead?`;
        aiErrorAlert.addAction("Use Original");
        aiErrorAlert.addCancelAction("Cancel Script");
        const errorChoice = await aiErrorAlert.presentAlert();

        if (errorChoice === -1) {
          console.log("Script cancelled due to AI processing error.");
          Script.complete();
          return;
        }
        finalText = originalInputText;
        console.log("Proceeding with original text after AI error.");
      }
    } else {
      if (!config.openaiApiKey) {
        console.log(
          "No OpenAI API Key configured. Skipping AI processing step."
        );
      } else if (!processWithAi) {
        console.log("User did not select AI processing option in the form.");
      } else if (
        config.openaiApiKey &&
        originalInputText.trim().length < MIN_LENGTH_FOR_AI
      ) {
        console.log(
          `Text length (${
            originalInputText.trim().length
          }) is less than minimum (${MIN_LENGTH_FOR_AI}). Skipping AI processing.`
        );
      }
      finalText = originalInputText;
    }

    const memoTitle = `Quick Capture - ${new Date().toLocaleString()}`;
    createdMemo = await createMemo(config, memoTitle);

    if (!createdMemo || !createdMemo.name || !createdMemo.name.includes("/")) {
      console.error(
        "Failed to get valid memo name from creation response.",
        createdMemo
      );
      throw new Error("Could not determine the new memo's name/ID.");
    }
    memoId = createdMemo.name.split("/").pop();
    if (!memoId) {
      console.error(`Failed to extract ID from memo name: ${createdMemo.name}`);
      throw new Error(`Invalid memo name format received: ${createdMemo.name}`);
    }
    console.log(`Memo created successfully with ID: ${memoId}`);

    await addCommentToMemo(config, memoId, finalText);
    console.log("Comment added successfully!");

    let showAlerts = !(
      typeof args.runsInWidget === "boolean" && args.runsInWidget
    );
    if (!showAlerts) {
      console.log("Running in widget context, skipping success alert.");
    }

    if (showAlerts) {
      const successAlert = new Alert();
      successAlert.title = "Success";
      successAlert.message = "Memo and comment added to Memos.";
      if (finalText !== originalInputText) {
        successAlert.message += "\n(Text processed by AI)";
      }
      await successAlert.presentAlert();
    }
  } catch (e) {
    console.error(`Script execution failed: ${e}`);
    let showAlerts = !(
      typeof args.runsInWidget === "boolean" && args.runsInWidget
    );
    if (!showAlerts) {
      console.log("Running in widget context, skipping error alert.");
    }

    if (showAlerts) {
      const errorAlert = new Alert();
      errorAlert.title = "Error";
      const errorMessage = e.message || "An unknown error occurred.";
      errorAlert.message = `Script failed: ${errorMessage}`;

      if (e.message) {
        if (e.message.includes("401")) {
          if (e.message.toLowerCase().includes("openai")) {
            errorAlert.message +=
              "\n\nCheck if your OpenAI API Key is correct and your account is active.";
          } else {
            errorAlert.message +=
              "\n\nCheck if your Memos Access Token is correct and has not expired.";
          }
        } else if (
          e.message.includes("404") &&
          e.message.toLowerCase().includes("memos")
        ) {
          errorAlert.message += "\n\nCheck if your Memos URL path is correct.";
        } else if (
          e.message.includes("ENOTFOUND") ||
          e.message.includes("Could not connect") ||
          e.message.includes("timed out")
        ) {
          errorAlert.message +=
            "\n\nCheck your network connection and if the Memos URL/OpenAI service is reachable.";
        } else if (
          e.message.toLowerCase().includes("openai") &&
          e.message.toLowerCase().includes("quota")
        ) {
          errorAlert.message += "\n\nCheck your OpenAI account usage/quota.";
        } else if (e.message.includes("Configuration cancelled")) {
        }
      }
      await errorAlert.presentAlert();
    }
  } finally {
    console.log("Script finished.");
    Script.complete();
  }
})();
