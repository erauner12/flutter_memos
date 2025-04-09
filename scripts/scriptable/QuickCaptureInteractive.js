// Variables used by Scriptable.
// These must be at the very top of the file. Do not edit.
// icon-color: green; icon-glyph: comment-dots;

// Configuration Keys
const KEYCHAIN_URL_KEY = "memos_instance_url";
const KEYCHAIN_TOKEN_KEY = "memos_access_token";
const KEYCHAIN_OPENAI_KEY = "openai_api_key"; // Added for OpenAI

// --- Helper Functions ---

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
 * Presents an HTML form in a WebView, handling interactive actions (paste, dictate)
 * before waiting for final submission or dismissal.
 * The HTML should contain JavaScript that calls `completion({action: '...', data: ...})`.
 * Actions can be 'paste', 'dictate', or 'submit'.
 * @param {string} htmlContent - The HTML string to display.
 * @param {boolean} [fullscreen=false] - Whether to present fullscreen.
 * @returns {Promise<any|null>} The data from the 'submit' action, or null if dismissed/error.
 */
async function presentWebViewForm(htmlContent, fullscreen = false) {
  console.log("Configuring interactive WebView form...");
  const wv = new WebView();
  wv.isPresented = false; // Track presentation state

  try {
    console.log("Loading HTML into WebView instance...");
    await wv.loadHTML(htmlContent);
    console.log("HTML loaded.");

    // Loop to handle interactions until submit or dismissal
    while (true) {
      console.log("WebView Loop: Setting up listener for next action/submit...");

      // JavaScript to initialize the form (if not already done) and listen
      const listenerScript = `
        if (typeof initializeForm === 'function' && !window.formInitialized) {
            console.log("Calling initializeForm() from listenerScript.");
            initializeForm();
            window.formInitialized = true; // Prevent re-initialization
        } else if (!window.formInitialized) {
             console.error("initializeForm function not found in HTML script.");
             if (typeof completion === 'function') {
                completion({ error: "Initialization function missing in HTML" });
             } else {
                console.error("CRITICAL: completion function not available during init check.");
             }
        }
        // Scriptable waits for completion() call via useCallback: true
        console.log("Listener active. Waiting for completion() call (paste, dictate, submit, or error)...");
      `;

      const evaluatePromise = wv.evaluateJavaScript(listenerScript, true); // Waits for completion()

      const presentPromise = new Promise((resolve, reject) => {
        // Only present *once* if it hasn't been presented yet.
        if (!wv.isPresented) {
           console.log(`Presenting WebView (fullscreen: ${fullscreen})...`);
           wv.present(fullscreen).then(() => {
               console.log("WebView dismissal detected by present().then().");
               wv.isPresented = false; // Mark as dismissed
               reject(new Error("WebView dismissed manually"));
           }).catch(reject);
           wv.isPresented = true; // Mark as presented
        } else {
           // If already presented, this promise essentially waits indefinitely,
           // relying on evaluatePromise or a dismissal error to break the race.
           // We create a promise that never resolves on its own but can be rejected
           // if an external event (like dismissal) occurs. Scriptable's internal
           // handling of dismissal might trigger rejection here.
           // This ensures Promise.race still works correctly on subsequent loops.
           const waitPromise = new Promise((res, rej) => { /* never resolves */ });
           // We rely on the fact that if the WV is dismissed, the evaluatePromise
           // might also reject or the overall script context might change.
           // The original present().then() handles the initial dismissal detection.
           resolve(waitPromise); // Resolve with the non-resolving promise
        }
      });


      let result;
      try {
          console.log("WebView Loop: Waiting for Promise.race (action/submit vs dismissal)...");
          // presentPromise here either starts presentation or waits indefinitely if already presented
          result = await Promise.race([evaluatePromise, presentPromise]);
          console.log("WebView Loop: Promise.race resolved with:", result);
      } catch (e) {
          // This catches dismissal from presentPromise rejection (primarily on first presentation)
          // or potentially errors during evaluateJavaScript if the view was closed abruptly.
          if (e.message === "WebView dismissed manually") {
              console.log("WebView Loop: Caught manual dismissal. Exiting loop.");
              return null; // User dismissed the form
          } else {
              console.error(`WebView Loop: Error during Promise.race: ${e}`);
              // Attempt to dismiss if it seems like it might still be presented
              if (wv.isPresented) {
                  try { await wv.dismiss(); wv.isPresented = false; } catch (dismissErr) { console.warn("Error dismissing WV on race error:", dismissErr); }
              }
              throw e; // Re-throw other errors
          }
      }

      // --- Handle the result from evaluatePromise ---
      if (result && result.error) {
          console.error(`WebView Loop: Error received from JS: ${result.error}`, result.details || '');
          // Show alert for JS errors
          let errorAlert = new Alert();
          errorAlert.title = "WebView Form Error";
          errorAlert.message = `An error occurred in the form: ${result.error}\n${result.details || ''}`;
          await errorAlert.presentAlert();
           if (wv.isPresented) {
               try { await wv.dismiss(); wv.isPresented = false; } catch (dismissErr) { console.warn("Error dismissing WV on JS error:", dismissErr); }
           }
          return null; // Exit on JS error
      } else if (result && result.action) {
          switch (result.action) {
              case 'submit':
                  console.log("WebView Loop: Received 'submit' action. Returning data:", result.data);
                  // Scriptable should auto-dismiss on completion, but check just in case
                  if (wv.isPresented) {
                     try { await wv.dismiss(); wv.isPresented = false; } catch (dismissErr) { console.warn("Error dismissing WV after submit:", dismissErr); }
                  }
                  return result.data; // Final submission data

              case 'paste':
                  console.log("WebView Loop: Received 'paste' action. Getting clipboard...");
                  const clipboardText = Pasteboard.pasteString() || ""; // Get clipboard content
                  console.log(`Clipboard content length: ${clipboardText.length}`);
                  // Send text back to the WebView's updateTextArea function
                  // Use JSON.stringify to correctly escape the text for JS
                  try {
                    await wv.evaluateJavaScript(`updateTextArea(${JSON.stringify(clipboardText)})`, false);
                    console.log("WebView Loop: Sent clipboard text back to JS. Continuing loop.");
                  } catch (evalError) {
                     console.error("WebView Loop: Error sending paste data back to JS:", evalError);
                     // Handle error - maybe alert user?
                  }
                  // Continue loop to wait for next action/submit
                  break; // Go to next iteration of the while loop

              case 'dictate':
                  console.log("WebView Loop: Received 'dictate' action. Starting dictation...");
                  try {
                      // Temporarily dismiss the WebView to allow Dictation UI
                      if (wv.isPresented) {
                          console.log("Temporarily dismissing WebView for Dictation...");
                          await wv.dismiss();
                          wv.isPresented = false; // Mark as not presented
                          await new Promise(resolve => setTimeout(resolve, 300)); // Small delay
                      }

                      const dictatedText = await Dictation.start();
                      console.log(`Dictation result length: ${dictatedText ? dictatedText.length : 'null'}`);

                      // Re-present the WebView before sending text back
                      console.log("Re-presenting WebView after Dictation...");
                      // Need to reload HTML or state might be lost? Test this.
                      // Let's try without reloading first.
                      // await wv.loadHTML(htmlContent); // Re-load might be necessary
                      await wv.present(fullscreen);
                      wv.isPresented = true;
                      await new Promise(resolve => setTimeout(resolve, 500)); // Delay for WebView to potentially re-render

                      // Re-initialize JS listeners after re-presenting
                       await wv.evaluateJavaScript(`
                           window.formInitialized = false; // Force re-init
                           if (typeof initializeForm === 'function') {
                               initializeForm();
                               window.formInitialized = true;
                               console.log('Re-initialized form after dictation re-present.');
                           } else { console.error('initializeForm not found after re-presenting.'); }
                       `, false);


                      if (dictatedText) {
                          // Send dictated text back to the WebView
                          await wv.evaluateJavaScript(`updateTextArea(${JSON.stringify(dictatedText)})`, false);
                          console.log("WebView Loop: Sent dictated text back to JS. Continuing loop.");
                      } else {
                          console.log("WebView Loop: Dictation returned no text.");
                      }
                  } catch (dictationError) {
                      console.error(`WebView Loop: Dictation failed: ${dictationError}`);
                      // Re-present WV if it was dismissed and dictation failed
                      if (!wv.isPresented) {
                          try {
                              await wv.present(fullscreen);
                              wv.isPresented = true;
                               await wv.evaluateJavaScript(`alert('Dictation failed: ${escapeHtml(dictationError.message)}')`, false);
                          } catch (representError) {
                              console.error("Failed to re-present WebView after dictation error:", representError);
                          }
                      } else {
                           // If still presented, just show alert
                           try {
                              await wv.evaluateJavaScript(`alert('Dictation failed: ${escapeHtml(dictationError.message)}')`, false);
                           } catch (alertError) { console.error("Failed to show dictation error alert:", alertError); }
                      }
                  }
                  // Continue loop to wait for next action/submit
                  break; // Go to next iteration of the while loop

              default:
                  console.warn(`WebView Loop: Received unknown action: ${result.action}`);
                  // Continue loop
                  break;
          }
      } else {
          // Should not happen if evaluatePromise resolved without error/action, but handle defensively
          console.warn("WebView Loop: evaluatePromise resolved with unexpected result:", result);
          // Continue loop
      }

    } // End while loop

  } catch (e) {
      // Catch errors from initial loadHTML or unexpected errors in the loop/race
      console.error(`Error during interactive WebView operation: ${e}`);
      // Ensure WebView is dismissed if an error occurs and it's still presented
      if (wv.isPresented) {
         try { await wv.dismiss(); wv.isPresented = false; } catch (dismissErr) { console.warn("Error dismissing WV on failure:", dismissErr); }
      }
      return null; // Return null on error
  }
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
            try {
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
                            // Use 'submit' action for consistency
                            completion({
                                action: 'submit',
                                data: {
                                    url: url,
                                    token: token,
                                    openaiApiKey: openaiApiKey || null // Return null if empty
                                }
                            });
                        } else {
                            console.error('CRITICAL: completion function unexpectedly not available!');
                            alert('Error: Cannot submit config form due to internal issue.');
                        }
                    }
                });
                console.log("Config form initialized.");
            } catch (initError) {
                console.error("Error during config form initialization:", initError);
                alert("A critical error occurred setting up the configuration form.");
                if (typeof completion === 'function') completion({ error: "Initialization crashed", details: initError.message });
            }
        }
         // Do NOT call initializeForm() here directly. Called by presentWebViewForm.
    </script>
</body>
</html>
`;
}

/**
 * Generates HTML for the main text input form, including Paste and Dictate buttons.
 * @param {string} [prefillText=''] - Text to pre-fill the textarea (e.g., from Share Sheet).
 * @param {boolean} [showAiOption=false] - Whether to show the AI processing checkbox.
 * @returns {string} HTML content for the input form.
 */
function generateInputFormHtml(prefillText = "", showAiOption = false) {
  const css = `
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; padding: 15px; display: flex; flex-direction: column; height: 95vh; background-color: #f8f8f8; color: #333; }
        textarea { flex-grow: 1; width: 95%; padding: 10px; margin-bottom: 15px; border: 1px solid #ccc; border-radius: 8px; font-size: 16px; resize: none; }
        .button-bar { display: flex; gap: 10px; margin-bottom: 15px; }
        .button-bar button { flex-grow: 1; padding: 10px 15px; background-color: #e0e0e0; color: #333; border: 1px solid #ccc; border-radius: 8px; cursor: pointer; font-size: 14px; }
        .button-bar button:hover { background-color: #d0d0d0; }
        button[type=submit] { padding: 12px 20px; background-color: #007aff; color: white; border: none; border-radius: 8px; cursor: pointer; font-size: 16px; width: 100%; margin-top: auto; }
        button[type=submit]:hover { background-color: #0056b3; }
        .options { margin-bottom: 15px; display: flex; align-items: center; }
        label[for=useAi] { margin-left: 8px; font-weight: normal; }
        input[type=checkbox] { width: 18px; height: 18px; }
        h2 { margin-top: 0; color: #111; }
        .clipboard-notice { font-size: 0.9em; color: #666; margin-bottom: 10px; }
        form { display: flex; flex-direction: column; flex-grow: 1; }
    `;

  const shareSheetNotice = prefillText
    ? '<div class="clipboard-notice">Text pre-filled from Share Sheet.</div>'
    : "";
  const aiCheckboxHtml = showAiOption
    ? `
        <div class="options">
            <input type="checkbox" id="useAi" name="useAi">
            <label for="useAi">Process with AI (Fix Grammar & Summarize)</label>
        </div>
    `
    : "";

  // Escape prefillText for safe insertion into textarea
  const escapedPrefillText = escapeHtml(prefillText);

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
        ${shareSheetNotice}
        <form id="inputForm">
            <textarea id="memoContent" name="memoContent" placeholder="Type, paste, or dictate your memo content here..." required>${escapedPrefillText}</textarea>

            <div class="button-bar">
                <button type="button" id="pasteButton">Paste from Clipboard</button>
                <button type="button" id="dictateButton">Start Dictation</button>
            </div>

            ${aiCheckboxHtml}
            <button type="submit">Add Memo</button>
        </form>

        <script>
            // Function called by Scriptable to update the text area
            function updateTextArea(text) {
                const contentInput = document.getElementById('memoContent');
                if (contentInput && text != null) { // Check if text is not null/undefined
                    // Append text with a space if there's existing content
                    const currentText = contentInput.value;
                    contentInput.value = currentText ? currentText + " " + text : text;
                    contentInput.focus(); // Keep focus
                    console.log("Text area updated.");
                } else {
                    console.error("Could not find text area or text was null.");
                }
            }

            // Function called by Scriptable's evaluateJavaScript to set up listeners
            function initializeForm() {
                try {
                    const form = document.getElementById('inputForm');
                    const contentInput = document.getElementById('memoContent');
                    const useAiCheckbox = document.getElementById('useAi'); // Might be null
                    const pasteButton = document.getElementById('pasteButton');
                    const dictateButton = document.getElementById('dictateButton');

                    if (!form || !contentInput || !pasteButton || !dictateButton) {
                        console.error("Required form elements not found during initialization.");
                        alert("Error initializing form elements.");
                        if (typeof completion === 'function') completion({ error: "Initialization failed: Elements missing" });
                        return;
                    }

                    // Submit Handler (Final action)
                    form.addEventListener('submit', (event) => {
                        event.preventDefault();
                        const content = contentInput.value.trim();
                        const processWithAi = useAiCheckbox ? useAiCheckbox.checked : false;

                        if (content) {
                             if (typeof completion === 'function') {
                                // Send final data with 'submit' action
                                completion({
                                    action: 'submit', // Indicate final submission
                                    data: {
                                        text: content,
                                        useAi: processWithAi
                                    }
                                });
                            } else {
                                 console.error('CRITICAL: completion function unexpectedly not available for submit!');
                                 alert('Error: Cannot submit form due to internal issue.');
                            }
                        } else {
                            alert("Please enter some content for the memo.");
                        }
                    });

                    // Paste Button Handler (Intermediate action)
                    pasteButton.addEventListener('click', () => {
                        console.log("Paste button clicked.");
                        if (typeof completion === 'function') {
                            completion({ action: 'paste' }); // Signal paste request
                        } else {
                            console.error('CRITICAL: completion function unexpectedly not available for paste!');
                            alert('Error: Cannot request paste due to internal issue.');
                        }
                    });

                    // Dictate Button Handler (Intermediate action)
                    dictateButton.addEventListener('click', () => {
                        console.log("Dictate button clicked.");
                        if (typeof completion === 'function') {
                            completion({ action: 'dictate' }); // Signal dictation request
                        } else {
                            console.error('CRITICAL: completion function unexpectedly not available for dictate!');
                            alert('Error: Cannot request dictation due to internal issue.');
                        }
                    });

                     // Auto-focus the text area on initial load
                     contentInput.focus();
                     console.log("Input form initialized with Paste/Dictate listeners and focused.");

                } catch (initError) {
                    console.error("Error during input form initialization:", initError);
                    alert("A critical error occurred setting up the input form.");
                    if (typeof completion === 'function') completion({ error: "Initialization crashed", details: initError.message });
                }
            }

             // Do NOT call initializeForm() here directly.
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
                try {
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
                            completion({ action: 'submit', data: { useProcessed: true } }); // Use submit action
                         } else { console.error('CRITICAL: completion function unexpectedly not available!'); alert('Error submitting choice.'); }
                    });

                    useOriginalButton.addEventListener('click', () => {
                         if (typeof completion === 'function') {
                            completion({ action: 'submit', data: { useProcessed: false } }); // Use submit action
                         } else { console.error('CRITICAL: completion function unexpectedly not available!'); alert('Error submitting choice.'); }
                    });
                    console.log("AI Confirm form initialized.");
                } catch (initError) {
                    console.error("Error during AI confirm form initialization:", initError);
                    alert("A critical error occurred setting up the AI confirmation form.");
                    if (typeof completion === 'function') completion({ error: "Initialization crashed", details: initError.message });
                }
            }
             // Do NOT call initializeForm() here directly. Called by presentWebViewForm.
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
    // Use presentWebViewForm to handle the config form submission
    const result = await presentWebViewForm(configHtml, false);

    // Check if the result contains the expected data structure
    if (!result || !result.url || !result.token) {
      console.log(
        "Configuration prompt cancelled or failed (WebView returned null or incomplete data)."
      );
      throw new Error(
        "Configuration cancelled or failed. Memos URL and Token are required."
      );
    }

    url = result.url;
    token = result.token;
    openaiApiKey = result.openaiApiKey; // Already handles null case

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


/**
 * Gets text input from Share Sheet or WebView form.
 * Allows user to paste from clipboard or dictate via buttons within the form.
 * @param {boolean} allowAiOption - Whether to include the AI processing option in the form.
 * @returns {Promise<{text: string, useAi: boolean}|null>} Object with input text and AI choice, or null if cancelled/empty.
 */
async function getInputText(allowAiOption = false) {
  console.log("Checking for input source...");
  let initialText = ""; // Start with empty text by default

  // 1. Check Share Sheet input (args.plainTexts) - Keep this pre-fill logic
  if (args.plainTexts && args.plainTexts.length > 0) {
    const sharedText = args.plainTexts.join("\n").trim();
    if (sharedText) {
      console.log("Using text from Share Sheet.");
      initialText = sharedText;
    }
  } else {
      console.log("No Share Sheet input found.");
      // Automatic clipboard check is removed. User must use the button.
  }

  // 2. Present WebView form for input (manual entry, paste, dictation, or editing pre-filled text)
  console.log("Presenting WebView form for text input.");
  const inputHtml = generateInputFormHtml(initialText, allowAiOption);
  // presentWebViewForm will now handle paste/dictation interactions
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
  const model = "gpt-3.5-turbo-instruct"; // Or another suitable completions model

  const request = new Request(endpoint);
  request.method = "POST";
  request.headers = {
    "Content-Type": "application/json",
    Authorization: `Bearer ${apiKey}`,
  };
  request.body = JSON.stringify({
    model: model,
    prompt: prompt,
    max_tokens: Math.max(150, Math.ceil(text.length * 1.2 + 100)), // Generous buffer
    temperature: 0.5,
    n: 1,
    stop: null,
  });
  request.timeoutInterval = 60; // Increase timeout
  request.allowInsecureRequest = false;

  try {
    console.log(`Sending request to OpenAI (${model})...`);
    const responseJson = await request.loadJSON();

    if (!responseJson || responseJson.error) {
      const errorMessage = responseJson?.error?.message || "Unknown OpenAI API error structure";
      console.error("OpenAI API Error in response:", responseJson?.error || responseJson);
      throw new Error(`OpenAI API Error: ${errorMessage}`);
    }
    if (!responseJson.choices || responseJson.choices.length === 0 || !responseJson.choices[0].text) {
      console.error("OpenAI response missing expected choices or text:", responseJson);
      throw new Error("OpenAI response did not contain the expected text.");
    }

    const processedText = responseJson.choices[0].text.trim();
    console.log("OpenAI processing successful. Result length:", processedText.length);
    return processedText;
  } catch (e) {
    console.error(`OpenAI Request Failed: ${e}`);
    let detailedMessage = e.message || "An unknown error occurred during the OpenAI request.";
    if (request.response && request.response.statusCode) {
      detailedMessage += ` (Status Code: ${request.response.statusCode})`;
    }
    throw new Error(`OpenAI Processing Failed: ${detailedMessage}`);
  }
}

/**
 * Adds a comment to an existing memo.
 * @param {{url: string, token: string}} config - Memos configuration.
 * @param {string} memoId - The string ID of the memo.
 * @param {string} commentText - The content of the comment.
 * @returns {Promise<object>} The API response for comment creation.
 * @throws {Error} If adding the comment fails.
 */
async function addCommentToMemo(config, memoId, commentText) {
  const endpoint = config.url.replace(/\/$/, "") + `/api/v1/memos/${memoId}/comments`;
  const body = { content: commentText };
  console.log(`Adding comment to memo ID: ${memoId}`);
  return await makeApiRequest(endpoint, "POST", config.token, body);
}

// --- Main Execution ---

(async () => {
  console.log("Starting Interactive Quick Capture to Memos script...");

  // --- Configuration Reset Logic ---
  if (args.queryParameters && args.queryParameters.resetConfig === "true") {
    console.log("Reset configuration argument detected.");
    const confirmAlert = new Alert();
    confirmAlert.title = "Reset Configuration?";
    confirmAlert.message = "Are you sure you want to remove the saved Memos URL, Access Token, and OpenAI Key?";
    confirmAlert.addAction("Reset");
    confirmAlert.addCancelAction("Cancel");
    const confirmation = await confirmAlert.presentAlert();
    if (confirmation === 0) {
      console.log("Removing configuration from Keychain...");
      Keychain.remove(KEYCHAIN_URL_KEY);
      Keychain.remove(KEYCHAIN_TOKEN_KEY);
      if (Keychain.contains(KEYCHAIN_OPENAI_KEY)) Keychain.remove(KEYCHAIN_OPENAI_KEY);
      console.log("Configuration removed.");
      const successAlert = new Alert();
      successAlert.title = "Configuration Reset";
      successAlert.message = "Configuration removed. Run the script again to reconfigure.";
      await successAlert.presentAlert();
      Script.complete(); return;
    } else {
      console.log("Configuration reset cancelled."); Script.complete(); return;
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
      Script.complete(); return;
    }

    originalInputText = inputData.text;
    let processWithAi = inputData.useAi;
    finalText = originalInputText;

    const MIN_LENGTH_FOR_AI = 20;

    if (processWithAi && config.openaiApiKey && originalInputText.trim().length >= MIN_LENGTH_FOR_AI) {
      console.log("User opted for AI processing. Calling OpenAI...");
      let processingAlert = null;
      try {
        processingAlert = new Alert();
        processingAlert.title = "Processing with AI...";
        processingAlert.message = "Please wait.";
        processingAlert.present(); // Show non-blocking alert

        const processedResult = await processTextWithOpenAI(config.openaiApiKey, originalInputText);

        if (processingAlert && typeof processingAlert.dismiss === 'function') {
           try { processingAlert.dismiss(); } catch (dismissError) { console.warn("Could not dismiss processing alert:", dismissError); }
        }
        processingAlert = null; // Clear reference

        console.log("AI processing successful. Asking for confirmation via WebView.");
        const confirmHtml = generateAiConfirmHtml(originalInputText, processedResult);
        const confirmResult = await presentWebViewForm(confirmHtml, false); // Use presentWebViewForm

        // Check the structure returned by presentWebViewForm for AI confirm
        if (confirmResult && typeof confirmResult.useProcessed !== 'undefined') {
            if (confirmResult.useProcessed === true) {
                finalText = processedResult;
                console.log("User confirmed using AI processed text via WebView.");
            } else {
                finalText = originalInputText;
                console.log("User chose to revert to original text via WebView.");
            }
        } else {
             finalText = originalInputText;
             console.log("AI confirmation cancelled or failed. Reverting to original text.");
        }

      } catch (aiError) {
        console.error(`AI Processing Failed: ${aiError}`);
        if (processingAlert && typeof processingAlert.dismiss === 'function') {
           try { processingAlert.dismiss(); } catch (dismissError) { console.warn("Could not dismiss processing alert:", dismissError); }
        }

        const aiErrorAlert = new Alert();
        aiErrorAlert.title = "AI Processing Error";
        aiErrorAlert.message = `Failed to process text with AI:\n${aiError.message}\n\nUse original text instead?`;
        aiErrorAlert.addAction("Use Original");
        aiErrorAlert.addCancelAction("Cancel Script");
        const errorChoice = await aiErrorAlert.presentAlert();

        if (errorChoice === -1) { // Cancelled
          console.log("Script cancelled due to AI processing error.");
          Script.complete(); return;
        }
        finalText = originalInputText; // Use original on error confirmation
        console.log("Proceeding with original text after AI error.");
      }
    } else {
      // Log reasons for skipping AI
      if (!config.openaiApiKey) console.log("No OpenAI API Key configured. Skipping AI.");
      else if (!processWithAi) console.log("User did not select AI processing.");
      else if (config.openaiApiKey && originalInputText.trim().length < MIN_LENGTH_FOR_AI) console.log(`Text length (${originalInputText.trim().length}) < min (${MIN_LENGTH_FOR_AI}). Skipping AI.`);
      finalText = originalInputText;
    }

    const memoTitle = `Quick Capture - ${new Date().toLocaleString()}`;
    createdMemo = await createMemo(config, memoTitle);

    if (!createdMemo || !createdMemo.name || !createdMemo.name.includes("/")) {
      console.error("Failed to get valid memo name from creation response.", createdMemo);
      throw new Error("Could not determine the new memo's name/ID.");
    }
    // Extract ID from name like "memos/101" -> "101"
    memoId = createdMemo.name.split("/").pop();
    if (!memoId) {
      console.error(`Failed to extract ID from memo name: ${createdMemo.name}`);
      throw new Error(`Invalid memo name format received: ${createdMemo.name}`);
    }
    console.log(`Memo created successfully with ID: ${memoId}`);

    await addCommentToMemo(config, memoId, finalText);
    console.log("Comment added successfully!");

    // Show success alert only if not running in widget context
    let showAlerts = !(typeof args.runsInWidget === "boolean" && args.runsInWidget);
    if (showAlerts) {
      const successAlert = new Alert();
      successAlert.title = "Success";
      successAlert.message = "Memo and comment added to Memos.";
      if (finalText !== originalInputText) {
        successAlert.message += "\n(Text processed by AI)";
      }
      await successAlert.presentAlert();
    } else {
        console.log("Running in widget context, skipping success alert.");
    }

  } catch (e) {
    console.error(`Script execution failed: ${e}`);
    // Show error alert only if not running in widget context
    let showAlerts = !(typeof args.runsInWidget === "boolean" && args.runsInWidget);
    if (showAlerts) {
      const errorAlert = new Alert();
      errorAlert.title = "Error";
      const errorMessage = e.message || "An unknown error occurred.";
      errorAlert.message = `Script failed: ${errorMessage}`;
      // Add specific hints based on error message
      if (e.message) {
        if (e.message.includes("401")) {
          errorAlert.message += e.message.toLowerCase().includes("openai") ? "\n\nCheck OpenAI Key/Account." : "\n\nCheck Memos Token.";
        } else if (e.message.includes("404") && e.message.toLowerCase().includes("memos")) {
          errorAlert.message += "\n\nCheck Memos URL Path.";
        } else if (e.message.includes("ENOTFOUND") || e.message.includes("Could not connect") || e.message.includes("timed out")) {
          errorAlert.message += "\n\nCheck Network/URL Reachability.";
        } else if (e.message.toLowerCase().includes("openai") && e.message.toLowerCase().includes("quota")) {
          errorAlert.message += "\n\nCheck OpenAI Quota.";
        }
      }
      await errorAlert.presentAlert();
    } else {
        console.log("Running in widget context, skipping error alert.");
    }
  } finally {
    console.log("Script finished.");
    Script.complete();
  }
})();
