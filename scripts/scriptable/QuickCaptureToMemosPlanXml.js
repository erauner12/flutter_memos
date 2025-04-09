// Variables used by Scriptable.
// These must be at the very top of the file. Do not edit.
// icon-color: blue; icon-glyph: tasks;

// Configuration Keys
const KEYCHAIN_URL_KEY = "memos_instance_url";
const KEYCHAIN_TOKEN_KEY = "memos_access_token";
const KEYCHAIN_OPENAI_KEY = "openai_api_key"; // Used for OpenAI

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
 * Actions can be 'paste', 'dictate', 'submit', or custom actions from review forms.
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
      console.log(
        "WebView Loop: Setting up listener for next action/submit..."
      );

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
          wv.present(fullscreen)
            .then(() => {
              // This .then() resolves when the user manually dismisses the WebView.
              console.log("WebView dismissal detected by present().then().");
              wv.isPresented = false; // Mark as dismissed
              reject(new Error("WebView dismissed manually"));
            })
            .catch(reject); // Catch errors during the initial presentation itself
          wv.isPresented = true; // Mark as presented
        } else {
          // If already presented, this promise essentially waits indefinitely.
          // We rely on evaluatePromise resolving or an error occurring.
          // Resolve with a promise that never settles on its own.
          resolve(new Promise(() => {}));
        }
      });

      let result;
      try {
        console.log(
          "WebView Loop: Waiting for Promise.race (action/submit vs dismissal)..."
        );
        result = await Promise.race([evaluatePromise, presentPromise]);
        console.log("WebView Loop: Promise.race resolved with:", result);
      } catch (e) {
        // This catches dismissal from presentPromise rejection (primarily on first presentation)
        if (e.message === "WebView dismissed manually") {
          console.log("WebView Loop: Caught manual dismissal. Exiting loop.");
          return null; // User dismissed the form
        } else {
          console.error(`WebView Loop: Error during Promise.race: ${e}`);
          // No wv.dismiss() to call here
          throw e; // Re-throw other errors
        }
      }

      // --- Handle the result from evaluatePromise ---
      if (result && result.error) {
        console.error(
          `WebView Loop: Error received from JS: ${result.error}`,
          result.details || ""
        );
        // Show alert for JS errors
        let errorAlert = new Alert();
        errorAlert.title = "WebView Form Error";
        errorAlert.message = `An error occurred in the form: ${result.error}\n${
          result.details || ""
        }`;
        await errorAlert.presentAlert();
        // No wv.dismiss() to call here
        return null; // Exit on JS error
      } else if (result && result.action) {
        switch (result.action) {
          case "submit":
            console.log(
              "WebView Loop: Received 'submit' action. Returning data:",
              result.data
            );
            // Scriptable should auto-dismiss on completion. No wv.dismiss() needed.
            return result.data; // Final submission data

          case "paste":
            console.log(
              "WebView Loop: Received 'paste' action. Getting clipboard..."
            );
            const clipboardText = Pasteboard.pasteString() || ""; // Get clipboard content
            console.log(`Clipboard content length: ${clipboardText.length}`);
            // Send text back to the WebView's updateTextArea function
            try {
              await wv.evaluateJavaScript(
                `updateTextArea(${JSON.stringify(clipboardText)})`,
                false
              );
              console.log(
                "WebView Loop: Sent clipboard text back to JS. Continuing loop."
              );
            } catch (evalError) {
              console.error(
                "WebView Loop: Error sending paste data back to JS:",
                evalError
              );
              // Handle error - maybe alert user?
            }
            // Continue loop to wait for next action/submit
            break; // Go to next iteration of the while loop

          case "dictate":
            console.log(
              "WebView Loop: Received 'dictate' action. Starting dictation..."
            );
            try {
              // Start dictation directly. It will overlay the WebView.
              const dictatedText = await Dictation.start();
              console.log(
                `Dictation result length: ${
                  dictatedText ? dictatedText.length : "null"
                }`
              );

              // Send dictated text back to the *existing* WebView instance
              if (dictatedText) {
                await wv.evaluateJavaScript(
                  `updateTextArea(${JSON.stringify(dictatedText)})`,
                  false
                );
                console.log(
                  "WebView Loop: Sent dictated text back to JS. Continuing loop."
                );
              } else {
                console.log("WebView Loop: Dictation returned no text.");
              }
            } catch (dictationError) {
              console.error(
                `WebView Loop: Dictation failed: ${dictationError}`
              );
              // Show alert within the still-present WebView
              try {
                await wv.evaluateJavaScript(
                  `alert('Dictation failed: ${escapeHtml(
                    dictationError.message
                  )}')`,
                  false
                );
              } catch (alertError) {
                console.error(
                  "Failed to show dictation error alert in WebView:",
                  alertError
                );
                // Fallback Scriptable alert if WebView alert fails
                let fallbackAlert = new Alert();
                fallbackAlert.title = "Dictation Error";
                fallbackAlert.message = `Dictation failed: ${dictationError.message}`;
                await fallbackAlert.presentAlert();
              }
            }
            // Continue loop to wait for next action/submit
            break; // Go to next iteration of the while loop

          default:
            console.warn(
              `WebView Loop: Received unknown action: ${result.action}`
            );
            // Continue loop
            break;
        }
      } else {
        // Should not happen if evaluatePromise resolved without error/action, but handle defensively
        console.warn(
          "WebView Loop: evaluatePromise resolved with unexpected result:",
          result
        );
        // Continue loop
      }
    } // End while loop
  } catch (e) {
    console.error(`Error during interactive WebView operation: ${e}`);
    // No wv.dismiss() to call here
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
            <label for="useAi">Process with AI (Generate Plan)</label>
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
 * Generates HTML to display the parsed AI plan for review.
 * @param {object} parsedPlanData - The structured plan object from parseAiXmlResponse.
 * @returns {string} HTML content string.
 */
function generatePlanReviewHtml(parsedPlanData) {
  const css = `
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; padding: 15px; background-color: #f8f8f8; color: #333; }
        .plan-description { margin-bottom: 20px; padding: 10px; background-color: #eef; border-radius: 5px; border: 1px solid #dde; }
        .file-block { margin-bottom: 15px; border: 1px solid #ccc; border-radius: 8px; background-color: white; overflow: hidden; }
        .file-header { background-color: #f0f0f0; padding: 8px 12px; border-bottom: 1px solid #ccc; font-weight: bold; }
        .file-path { font-family: monospace; font-size: 0.9em; }
        .file-action { float: right; font-size: 0.8em; background-color: #ddd; padding: 2px 6px; border-radius: 4px; text-transform: uppercase; }
        .change-block { padding: 10px 12px; border-bottom: 1px dashed #eee; }
        .change-block:last-child { border-bottom: none; }
        .change-description { font-style: italic; color: #555; margin-bottom: 8px; }
        .code-block { background-color: #f5f5f5; border: 1px solid #ddd; border-radius: 4px; padding: 8px; margin-top: 5px; white-space: pre-wrap; word-wrap: break-word; font-family: monospace; font-size: 0.85em; max-height: 200px; overflow-y: auto; }
        .code-block.search { border-left: 3px solid #ffcc00; } /* Yellow for search */
        .code-block.content { border-left: 3px solid #4caf50; } /* Green for content */
        .code-block.delete { border-left: 3px solid #f44336; color: #777; font-style: italic; } /* Red for delete */
        button { padding: 12px 15px; background-color: #007aff; color: white; border: none; border-radius: 8px; cursor: pointer; font-size: 16px; margin-right: 10px; margin-top: 10px; }
        button.secondary { background-color: #6c757d; }
        button:hover { opacity: 0.8; }
        h2 { margin-top: 0; color: #111; }
        p { color: #555; }
        .button-group { margin-top: 20px; text-align: center; }
    `;

  let filesHtml = "";
  if (
    parsedPlanData &&
    parsedPlanData.files &&
    parsedPlanData.files.length > 0
  ) {
    parsedPlanData.files.forEach((file) => {
      let changesHtml = "";
      if (file.changes && file.changes.length > 0) {
        file.changes.forEach((change) => {
          changesHtml += `
            <div class="change-block">
              <div class="change-description">${escapeHtml(
                change.description || "No description"
              )}</div>
          `;
          // Display search block only for modify/delegate edit actions
          if (
            change.search &&
            (file.action === "delegate edit" || file.action === "modify")
          ) {
            changesHtml += `<div><strong>Search/Context:</strong><pre class="code-block search">${escapeHtml(
              change.search
            )}</pre></div>`;
          }
          // Display content block for create/delegate edit/modify
          if (change.content && file.action !== "delete") {
            changesHtml += `<div><strong>Content/Change:</strong><pre class="code-block content">${escapeHtml(
              change.content
            )}</pre></div>`;
          }
          // Display message for delete action
          if (file.action === "delete") {
            changesHtml += `<pre class="code-block delete">(File to be deleted)</pre>`;
          }
          changesHtml += `</div>`; // Close change-block
        });
      } else {
        changesHtml = `<div class="change-block"><div class="change-description">No specific changes listed for this file action.</div></div>`;
      }

      filesHtml += `
        <div class="file-block">
          <div class="file-header">
            <span class="file-action">${escapeHtml(
              file.action || "unknown"
            )}</span>
            <span class="file-path">${escapeHtml(
              file.path || "No path specified"
            )}</span>
          </div>
          ${changesHtml}
        </div>
      `;
    });
  } else {
    filesHtml = "<p>No file changes specified in the plan.</p>";
  }

  const planDescriptionHtml = parsedPlanData.planText
    ? `<div class="plan-description"><strong>Plan:</strong> ${escapeHtml(
        parsedPlanData.planText
      )}</div>`
    : "<p>No overall plan description provided.</p>";

  return `
    <!DOCTYPE html>
    <html>
    <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Review AI Generated Plan</title>
        <style>${css}</style>
    </head>
    <body>
        <h2>Review AI Generated Plan</h2>
        <p>Review the plan generated by the AI. Choose whether to use this plan for the memo comment.</p>

        ${planDescriptionHtml}
        ${filesHtml}

        <div class="button-group">
            <button id="usePlan">Use This Plan</button>
            <button id="useOriginal" class="secondary">Use Original Text</button>
        </div>

        <script>
            // Wrap setup logic in a function
            function initializeForm() {
                try {
                    const usePlanButton = document.getElementById('usePlan');
                    const useOriginalButton = document.getElementById('useOriginal');

                    if (!usePlanButton || !useOriginalButton) {
                         console.error("Plan review form elements not found during initialization.");
                         alert("Error initializing plan review form elements.");
                         if (typeof completion === 'function') completion({ error: "Initialization failed: Elements missing" });
                         return;
                    }

                    usePlanButton.addEventListener('click', () => {
                         if (typeof completion === 'function') {
                            completion({ action: 'submit', data: { confirmedPlan: true } }); // Use submit action
                         } else { console.error('CRITICAL: completion function unexpectedly not available!'); alert('Error submitting choice.'); }
                    });

                    useOriginalButton.addEventListener('click', () => {
                         if (typeof completion === 'function') {
                            completion({ action: 'submit', data: { confirmedPlan: false } }); // Use submit action
                         } else { console.error('CRITICAL: completion function unexpectedly not available!'); alert('Error submitting choice.'); }
                    });
                    console.log("AI Plan Review form initialized.");
                } catch (initError) {
                    console.error("Error during AI plan review form initialization:", initError);
                    alert("A critical error occurred setting up the AI plan review form.");
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
 * Requests a plan from OpenAI in a specific XML format using Chat Completions.
 * @param {string} apiKey - OpenAI API Key.
 * @param {string} userRequest - The user's input/request for the AI.
 * @returns {Promise<string>} Raw XML string response from OpenAI.
 * @throws {Error} If the API request fails or returns an error.
 */
async function getAiPlanAsXml(apiKey, userRequest) {
  console.log("Requesting XML plan from OpenAI...");
  const endpoint = "https://api.openai.com/v1/chat/completions";
  // Use a recommended model for chat completions and instruction following
  const model = "gpt-4o"; // Or "gpt-3.5-turbo" or "gpt-4-turbo"

  // Define the XML formatting instructions (as provided in the prompt)
  const xmlFormattingInstructions = `
### Role
- You are a **code editing assistant**: You can fulfill edit requests and chat with the user about code or other questions. Provide complete instructions or code lines when replying with xml formatting.

### Capabilities
- Can create new files.
- Can delete existing files.
- Can produce instructions with placeholders for an external agent to finalize.

Avoid placeholders like \`...\` or \`// existing code here\`. Provide complete lines or code.

## Tools & Actions
1. **create** – Create a new file if it doesn’t exist.
2. **delete** – Remove a file entirely (empty <content>).
3. **delegate edit** – Provide targetted code change instructions that will be integrated by another ai model. Indicate <complexity> to help route changes to the right model.

### **Format to Follow for Repo Prompt's Diff Protocol**

<chatName="Brief descriptive name of the change"/>

<Plan>
Describe your approach or reasoning here.
</Plan>

<file path="path/to/example.swift" action="one_of_the_tools">
  <change>
    <description>Brief explanation of this specific change</description>
    <content>
===
// Provide placeholders or partial code. Must also include <complexity> after </content>.
===
    </content>
    <complexity>3</complexity> <!-- Always required for delegate edits -->
  </change>
  <!-- Add more <change> blocks if you have multiple edits for the same file -->
</file>

#### Tools Demonstration
1. \`<file path="NewFile.swift" action="create">\` – Full file in <content>
2. \`<file path="DeleteMe.swift" action="delete">\` – Empty <content>
3. \`<file path="DelegateMe.swift" action="delegate edit">\` – Placeholders in <content>, each <change> must include <complexity>

## Format Guidelines
1. **chatName**: Always Include \`<chatName="Descriptive Name"/>\` at the top, briefly summarizing the change/request.
2. **Plan**: Begin with a \`<Plan>\` block explaining your approach.
3. **<file> Tag**: e.g. \`<file path="Models/User.swift" action="...">\`. Must match an available tool.
4. **<change> Tag**: Provide \`<description>\` to clarify each change. Then \`<content>\` for new/modified code. Additional rules depend on your capabilities.
5. **Delegate Edit**: In \`<content>\`, place placeholders or partial code. Always include \`<complexity>\` in each \`<change>\`.
6. **create**: For new files, put the full file in <content>.
7. **delete**: Provide an empty <content>. The file is removed.
8. **delegate edit**: You can include placeholders or partial code. Use <complexity> to indicate difficulty.
9. **Escaping**: Escape quotes as \\" and backslashes as \\\\ where needed.

## Code Examples

-----
### Example: Create New File
<Plan>
Create a new RoundedButton for a custom Swift UIButton subclass.
</Plan>

<file path="Views/RoundedButton.swift" action="create">
  <change>
    <description>Create custom RoundedButton class</description>
    <content>
===
import UIKit
@IBDesignable
class RoundedButton: UIButton {
    @IBInspectable var cornerRadius: CGFloat = 0
}
===
    </content>
  </change>
</file>

-----
### Example: Delegate Edit
<chatName="Add email property and initializer to User"/>
<Plan>
Add a new \`var email: String\`, then modify the initializer accordingly.
</Plan>

<file path="Models/User.swift" action="delegate edit">
  <change>
    <description>Add \`var email: String\` to the \`User\` struct</description>
    <content>
===
struct User {
    let id: UUID
    var name: String
    // Add the new email property here
    var email: String
    // Other existing properties remain unchanged
}
===
    </content>
    <complexity>3</complexity>
  </change>

  <change>
    <description>Adjust the initializer to accept \`email: String\`</description>
    <content>
===
init(name: String, email: String) {
    self.id = UUID()
    self.name = name
    // Initialize the new email property
    self.email = email
}
// Other initializers and methods remain unchanged
===
    </content>
    <complexity>1</complexity>
  </change>
</file>

-----
### Example: Delete a File
<Plan>
Remove an obsolete file.
</Plan>

<file path="Obsolete/File.swift" action="delete">
  <change>
    <description>Completely remove the file from the project</description>
    <content>
===
===
    </content>
  </change>
</file>

## Final Notes
1. **delegate edit** Always include \`<complexity>\` in each \`<change>\`. Provide placeholders or partial code in \`<content>\`. Avoid writing too much code here. It should be clear enough to know what needs changing, while remainign concise. Use comments like // Existing code here to help localize your edits.
2. **delegate edit** Avoid rewriting too much code in a given change. Your task is to be succict and descriptive for each required edit. Make heavy use of comments and placeholders to help guide the engineer who will be tasked with integrating your changes into the designated file.
3. **delegate edit** Aim to make each change small and focused. It should be clear what needs to be changed, and how.
4. You can always **create** new files and **delete** existing files. Provide full code for create, and empty content for delete. Avoid creating files you know exist already.
5. If a file tree is provided, place your files logically within that structure. Respect the user’s relative or absolute paths.
6. If you see mention of capabilites not listed above in the user's chat history, do not try and use those capabilities.
7. Always include \`<chatName="Descriptive Name"/>\` near the top if you produce multi-file or complex changes.
8. Escape quotes as \\" and backslashes as \\\\ if necessary.
9. **IMPORTANT** WHEN MAKING FILE CHANGES, YOU MUST USE THE AVAILABLE XML FORMATTING CAPABILITIES PROVIDED ABOVE - IT IS THE ONLY WAY FOR YOUR CHANGES TO BE APPLIED.
10. The final output must apply cleanly with no leftover syntax errors.
`;

  // Construct the prompt for the Chat Completions API
  const messages = [
    {
      role: "system",
      content: `You are a helpful assistant that generates plans for code changes based on user requests. You MUST respond ONLY with the XML structure defined below. Do not include any introductory text, explanations, or markdown formatting outside the XML tags.

Here are the XML formatting instructions you MUST follow:
${xmlFormattingInstructions}`,
    },
    {
      role: "user",
      content: `Generate a plan in the specified XML format for the following request:

${userRequest}`,
    },
  ];

  const request = new Request(endpoint);
  request.method = "POST";
  request.headers = {
    "Content-Type": "application/json",
    Authorization: `Bearer ${apiKey}`,
  };
  request.body = JSON.stringify({
    model: model,
    messages: messages,
    max_tokens: 3000, // Adjust as needed, can be large for complex plans
    temperature: 0.3, // Lower temperature for more deterministic output
    n: 1,
    stop: null,
  });
  request.timeoutInterval = 90; // Increase timeout for potentially longer generation
  request.allowInsecureRequest = false;

  try {
    console.log(`Sending request to OpenAI Chat Completions (${model})...`);
    const responseJson = await request.loadJSON();

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
      !responseJson.choices[0].message ||
      !responseJson.choices[0].message.content
    ) {
      console.error(
        "OpenAI response missing expected structure (choices[0].message.content):",
        responseJson
      );
      throw new Error(
        "OpenAI response did not contain the expected message content."
      );
    }

    const xmlContent = responseJson.choices[0].message.content.trim();
    console.log(
      "OpenAI XML plan generation successful. Raw XML length:",
      xmlContent.length
    );
    // Basic check if it looks like XML
    if (!xmlContent.startsWith("<") || !xmlContent.endsWith(">")) {
      console.warn("OpenAI response doesn't look like XML:", xmlContent);
      // Decide whether to throw an error or try parsing anyway
      // throw new Error("OpenAI response did not appear to be valid XML.");
    }
    return xmlContent;
  } catch (e) {
    console.error(`OpenAI Request Failed: ${e}`);
    let detailedMessage =
      e.message || "An unknown error occurred during the OpenAI request.";
    if (request.response && request.response.statusCode) {
      detailedMessage += ` (Status Code: ${request.response.statusCode})`;
    }
    throw new Error(`OpenAI Plan Generation Failed: ${detailedMessage}`);
  }
}

/**
 * Parses the AI-generated XML plan into a JavaScript object.
 * @param {string} xmlString - The raw XML string from OpenAI.
 * @returns {object|null} Structured plan object or null on parsing error.
 */
function parseAiXmlResponse(xmlString) {
  console.log("Parsing AI XML response...");
  try {
    const parser = new XMLParser(xmlString);
    let parsedData = { chatName: "", planText: "", files: [] };
    let currentFile = null;
    let currentChange = null;
    let currentTag = null;
    let accumulatedChars = "";
    let parseError = false;

    parser.didStartElement = (name, attrs) => {
      currentTag = name.toLowerCase();
      accumulatedChars = ""; // Reset chars for new element
      // console.log(`Start Element: ${name}, Attrs: ${JSON.stringify(attrs)}`);
      if (currentTag === "file") {
        currentFile = {
          path: attrs.path || "",
          action: attrs.action || "",
          changes: [],
        };
      } else if (currentTag === "change") {
        currentChange = {
          description: "",
          content: "",
          complexity: null, // Initialize complexity
          search: "", // Initialize search (though not explicitly in the provided XML spec, good to handle)
        };
      }
    };

    parser.foundCharacters = (chars) => {
      accumulatedChars += chars;
    };

    parser.didEndElement = (name) => {
      const tagName = name.toLowerCase();
      const trimmedChars = accumulatedChars.trim();
      // console.log(`End Element: ${name}, Chars: "${trimmedChars}"`);

      if (tagName === "chatname") {
        parsedData.chatName = trimmedChars;
      } else if (tagName === "plan") {
        parsedData.planText = trimmedChars;
      } else if (tagName === "file") {
        if (currentFile) {
          parsedData.files.push(currentFile);
          currentFile = null;
        }
      } else if (tagName === "change") {
        if (currentChange && currentFile) {
          currentFile.changes.push(currentChange);
          currentChange = null;
        }
      } else if (currentChange) {
        // Handle tags within <change>
        if (tagName === "description") {
          currentChange.description = trimmedChars;
        } else if (tagName === "content") {
          // Remove potential === markers
          currentChange.content = trimmedChars
            .replace(/^===\s*|\s*===$/g, "")
            .trim();
        } else if (tagName === "complexity") {
          const complexityValue = parseInt(trimmedChars, 10);
          currentChange.complexity = isNaN(complexityValue)
            ? null
            : complexityValue;
        } else if (tagName === "search") {
          // Handle potential <search> tag
          currentChange.search = trimmedChars
            .replace(/^===\s*|\s*===$/g, "")
            .trim();
        }
      }
      currentTag = null; // Reset current tag context
      accumulatedChars = ""; // Reset chars after processing
    };

    parser.parseErrorOccurred = (line, column, message) => {
      console.error(`XML Parse Error at ${line}:${column}: ${message}`);
      parseError = true;
    };

    const success = parser.parse();

    if (!success || parseError) {
      console.error("XML parsing failed.");
      return null;
    }

    console.log("XML parsing successful.");
    // console.log("Parsed Data:", JSON.stringify(parsedData, null, 2));
    return parsedData;
  } catch (e) {
    console.error(`Error during XML parsing setup or execution: ${e}`);
    return null;
  }
}

/**
 * Formats the parsed plan data into a Markdown-like string for Memos.
 * @param {object} parsedPlanData - The structured plan object.
 * @returns {string} Formatted string representation of the plan.
 */
function formatPlanForMemo(parsedPlanData) {
  if (!parsedPlanData) return "Error: Could not format plan.";

  let output = "";

  if (parsedPlanData.chatName) {
    output += `# ${parsedPlanData.chatName}\n\n`;
  }

  if (parsedPlanData.planText) {
    output += `**Plan:**\n${parsedPlanData.planText}\n\n`;
  } else {
    output += "**Plan:** (No description provided)\n\n";
  }

  if (parsedPlanData.files && parsedPlanData.files.length > 0) {
    output += `**File Changes:**\n\n`;
    parsedPlanData.files.forEach((file, index) => {
      output += `--- File ${index + 1} ---\n`;
      output += `**Path:** \`${file.path || "N/A"}\`\n`;
      output += `**Action:** ${file.action || "N/A"}\n\n`;

      if (file.changes && file.changes.length > 0) {
        file.changes.forEach((change, changeIndex) => {
          output += `*Change ${changeIndex + 1}:*\n`;
          if (change.description) {
            output += `  *Description:* ${change.description}\n`;
          }
          if (change.complexity !== null) {
            output += `  *Complexity:* ${change.complexity}\n`;
          }
          if (
            change.search &&
            (file.action === "delegate edit" || file.action === "modify")
          ) {
            output += `  *Search/Context:*\n\`\`\`\n${change.search}\n\`\`\`\n`;
          }
          if (change.content && file.action !== "delete") {
            output += `  *Content/Change:*\n\`\`\`\n${change.content}\n\`\`\`\n`;
          }
          if (file.action === "delete") {
            output += `  *(File to be deleted)*\n`;
          }
          output += "\n";
        });
      } else {
        output += "  (No specific changes listed)\n\n";
      }
    });
  } else {
    output += "**File Changes:** (None specified)\n";
  }

  return output.trim();
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
  const endpoint =
    config.url.replace(/\/$/, "") + `/api/v1/memos/${memoId}/comments`;
  const body = { content: commentText };
  console.log(`Adding comment to memo ID: ${memoId}`);
  return await makeApiRequest(endpoint, "POST", config.token, body);
}

// --- Main Execution ---

(async () => {
  console.log(
    "Starting Interactive Quick Capture (with AI Plan) to Memos script..."
  );

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
      if (Keychain.contains(KEYCHAIN_OPENAI_KEY))
        Keychain.remove(KEYCHAIN_OPENAI_KEY);
      console.log("Configuration removed.");
      const successAlert = new Alert();
      successAlert.title = "Configuration Reset";
      successAlert.message =
        "Configuration removed. Run the script again to reconfigure.";
      await successAlert.presentAlert();
      Script.complete();
      return;
    } else {
      console.log("Configuration reset cancelled.");
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
  let planUsed = false; // Track if the AI plan was used

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
    finalText = originalInputText; // Default to original text

    // --- AI Plan Generation Flow ---
    if (processWithAi && config.openaiApiKey) {
      console.log("User opted for AI processing. Requesting XML plan...");
      let processingAlert = null;
      try {
        processingAlert = new Alert();
        processingAlert.title = "Generating AI Plan...";
        processingAlert.message = "Please wait.";
        processingAlert.present(); // Show non-blocking alert

        const rawXml = await getAiPlanAsXml(
          config.openaiApiKey,
          originalInputText
        );

        const parsedPlan = parseAiXmlResponse(rawXml);

        if (processingAlert && typeof processingAlert.dismiss === "function") {
          try {
            processingAlert.dismiss();
          } catch (e) {
            console.warn("Could not dismiss processing alert:", e);
          }
        }
        processingAlert = null; // Clear reference

        if (!parsedPlan) {
          throw new Error("Failed to parse the AI-generated XML plan.");
        }

        console.log(
          "AI plan parsed successfully. Asking for review via WebView."
        );
        const reviewHtml = generatePlanReviewHtml(parsedPlan);
        const reviewResult = await presentWebViewForm(reviewHtml, false); // Use presentWebViewForm

        // Check the structure returned by presentWebViewForm for plan review
        if (reviewResult && typeof reviewResult.confirmedPlan !== "undefined") {
          if (reviewResult.confirmedPlan === true) {
            finalText = formatPlanForMemo(parsedPlan); // Format the plan for saving
            planUsed = true;
            console.log("User confirmed using AI generated plan via WebView.");
          } else {
            finalText = originalInputText; // Revert to original text
            console.log("User chose to revert to original text via WebView.");
          }
        } else {
          finalText = originalInputText; // Revert on cancellation or error
          console.log(
            "AI plan review cancelled or failed. Reverting to original text."
          );
        }
      } catch (aiError) {
        console.error(`AI Plan Generation/Processing Failed: ${aiError}`);
        if (processingAlert && typeof processingAlert.dismiss === "function") {
          try {
            processingAlert.dismiss();
          } catch (e) {
            console.warn("Could not dismiss processing alert:", e);
          }
        }

        const aiErrorAlert = new Alert();
        aiErrorAlert.title = "AI Plan Error";
        aiErrorAlert.message = `Failed to generate or process AI plan:\n${aiError.message}\n\nUse original text instead?`;
        aiErrorAlert.addAction("Use Original");
        aiErrorAlert.addCancelAction("Cancel Script");
        const errorChoice = await aiErrorAlert.presentAlert();

        if (errorChoice === -1) {
          // Cancelled
          console.log("Script cancelled due to AI plan processing error.");
          Script.complete();
          return;
        }
        finalText = originalInputText; // Use original on error confirmation
        console.log("Proceeding with original text after AI error.");
      }
    } else {
      // Log reasons for skipping AI plan generation
      if (!config.openaiApiKey)
        console.log("No OpenAI API Key configured. Skipping AI plan.");
      else if (!processWithAi)
        console.log("User did not select AI processing.");
      finalText = originalInputText; // Ensure final text is set if AI wasn't used
    }
    // --- End AI Plan Generation Flow ---

    // --- Memos Creation ---
    const memoTitle = `Quick Capture - ${new Date().toLocaleString()}`;
    createdMemo = await createMemo(config, memoTitle);

    if (!createdMemo || !createdMemo.name || !createdMemo.name.includes("/")) {
      console.error(
        "Failed to get valid memo name from creation response.",
        createdMemo
      );
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
    let showAlerts = !(
      typeof args.runsInWidget === "boolean" && args.runsInWidget
    );
    if (showAlerts) {
      const successAlert = new Alert();
      successAlert.title = "Success";
      successAlert.message = "Memo and comment added to Memos.";
      if (planUsed) {
        successAlert.message += "\n(Used AI generated plan)";
      }
      await successAlert.presentAlert();
    } else {
      console.log("Running in widget context, skipping success alert.");
    }
  } catch (e) {
    console.error(`Script execution failed: ${e}`);
    // Show error alert only if not running in widget context
    let showAlerts = !(
      typeof args.runsInWidget === "boolean" && args.runsInWidget
    );
    if (showAlerts) {
      const errorAlert = new Alert();
      errorAlert.title = "Error";
      const errorMessage = e.message || "An unknown error occurred.";
      errorAlert.message = `Script failed: ${errorMessage}`;
      // Add specific hints based on error message
      if (e.message) {
        if (e.message.includes("401")) {
          errorAlert.message += e.message.toLowerCase().includes("openai")
            ? "\n\nCheck OpenAI Key/Account."
            : "\n\nCheck Memos Token.";
        } else if (
          e.message.includes("404") &&
          e.message.toLowerCase().includes("memos")
        ) {
          errorAlert.message += "\n\nCheck Memos URL Path.";
        } else if (
          e.message.includes("ENOTFOUND") ||
          e.message.includes("Could not connect") ||
          e.message.includes("timed out")
        ) {
          errorAlert.message += "\n\nCheck Network/URL Reachability.";
        } else if (
          e.message.toLowerCase().includes("openai") &&
          e.message.toLowerCase().includes("quota")
        ) {
          errorAlert.message += "\n\nCheck OpenAI Quota.";
        } else if (e.message.toLowerCase().includes("xml parse error")) {
          errorAlert.message += "\n\nAI response was not valid XML.";
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
