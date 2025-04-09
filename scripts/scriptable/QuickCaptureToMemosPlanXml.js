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
    .replace(/&/g, "&")
    .replace(/</g, "<")
    .replace(/>/g, ">")
    .replace(/"/g, """)
    .replace(/'/g, "'");
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
        // Ensure form initialization happens only once
        if (typeof initializeForm === 'function' && !window.formInitialized) {
            console.log("Calling initializeForm() from listenerScript.");
            try {
                initializeForm();
                window.formInitialized = true; // Mark as initialized
            } catch (initErr) {
                 console.error("Error executing initializeForm():", initErr);
                 if (typeof completion === 'function') {
                    completion({ error: "Form initialization script failed", details: initErr.message });
                 } else {
                    console.error("CRITICAL: completion function not available during init error.");
                 }
            }
        } else if (!window.formInitialized && typeof initializeForm !== 'function') {
             console.error("initializeForm function not found in HTML script.");
             if (typeof completion === 'function') {
                completion({ error: "Initialization function missing in HTML" });
             } else {
                console.error("CRITICAL: completion function not available during init check.");
             }
             // Mark as initialized even if missing to prevent repeated errors
             window.formInitialized = true;
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
          resolve(new Promise(() => {})); // A promise that never resolves on its own
        }
      });

      let result;
      try {
        console.log(
          "WebView Loop: Waiting for Promise.race (action/submit vs dismissal)..."
        );
        // Wait for either the JS completion() call or the user dismissing the view
        result = await Promise.race([evaluatePromise, presentPromise]);
        console.log("WebView Loop: Promise.race resolved with:", result);
      } catch (e) {
        // This catches dismissal from presentPromise rejection
        if (e.message === "WebView dismissed manually") {
          console.log("WebView Loop: Caught manual dismissal. Exiting loop.");
          return null; // User dismissed the form
        } else {
          console.error(`WebView Loop: Error during Promise.race: ${e}`);
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
        return null; // Exit on JS error
      } else if (result && result.action) {
        switch (result.action) {
          case "submit":
            console.log(
              "WebView Loop: Received 'submit' action. Returning data:",
              result.data
            );
            // Scriptable should auto-dismiss on completion.
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
                false // Don't wait for completion here
              );
              console.log(
                "WebView Loop: Sent clipboard text back to JS. Continuing loop."
              );
            } catch (evalError) {
              console.error(
                "WebView Loop: Error sending paste data back to JS:",
                evalError
              );
              // Optionally alert the user here
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
                  false // Don't wait for completion here
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
              // Show alert within the still-present WebView if possible
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
    // Ensure WebView is dismissed if an error occurs before returning
    // Note: Scriptable often handles dismissal on script completion/error,
    // but explicit dismissal might be needed in some complex error scenarios.
    // However, calling dismiss() on an unpresented WV throws error. Check isPresented.
    // if (wv.isPresented) {
    //   await wv.dismiss(); // Consider if needed, might be redundant
    // }
    return null; // Return null on error
  }
}

/**
 * Generates HTML for the Memos configuration form.
 * @param {string|null} existingUrl - Pre-fill URL if available.
 * @param {string|null} existingToken - Pre-fill Token if available (masked).
 * @param {string|null} existingOpenAIKey - Pre-fill OpenAI Key if available (masked).
 * @returns {string} HTML content for the configuration form.
 */
function generateConfigFormHtml(existingUrl, existingToken, existingOpenAIKey) {
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
        .info { font-size: 0.9em; color: #666; margin-bottom: 15px; }
    `;

  // Pre-fill values if provided
  const urlValue = existingUrl ? `value="${escapeHtml(existingUrl)}"` : "";
  // Don't pre-fill passwords directly for security, maybe show placeholder if exists
  const tokenPlaceholder = existingToken ? `placeholder="Exists (Enter new to change)"` : `placeholder="Enter Memos Token"`;
  const openaiKeyPlaceholder = existingOpenAIKey ? `placeholder="Exists (Enter new to change)"` : `placeholder="Enter OpenAI Key (Optional)"`;

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
        <div class="info">Existing tokens/keys are not shown. Enter a new value only if you need to change it. Leave blank to keep the existing value (if any).</div>
        <form id="configForm">
            <label for="memosUrl">Memos URL:</label>
            <input type="text" id="memosUrl" name="memosUrl" ${urlValue} required placeholder="https://your-memos.com">
            <div id="urlError" class="error" style="display: none;"></div>

            <label for="accessToken">Access Token:</label>
            <input type="password" id="accessToken" name="accessToken" ${tokenPlaceholder} >
            <div id="tokenError" class="error" style="display: none;"></div>

            <label for="openaiKey">OpenAI API Key (Optional):</label>
            <input type="password" id="openaiKey" name="openaiKey" ${openaiKeyPlaceholder}>

            <button type="submit">Save Configuration</button>
        </form>

        <script>
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
                    // Get potentially new values, will be empty strings if user didn't type anything
                    const newToken = tokenInput.value.trim();
                    const newOpenaiApiKey = openaiInput.value.trim();

                    // URL validation
                    if (!url) {
                        urlError.textContent = 'Memos URL is required.';
                        urlError.style.display = 'block';
                        isValid = false;
                    } else if (!url.toLowerCase().startsWith('http://') && !url.toLowerCase().startsWith('https://')) {
                        urlError.textContent = 'URL must start with http:// or https://';
                        urlError.style.display = 'block';
                        isValid = false;
                    }

                    // Token validation: Only require if *no* token exists yet OR if user entered a new one.
                    // This logic needs the existing token status, which isn't easily available here.
                    // Simplification: We'll handle saving logic in the main script. Just pass values back.
                    // We *do* need to ensure *some* token will exist after this save.
                    // Let's pass back whether the fields were touched.

                    if (isValid) {
                        if (typeof completion === 'function') {
                            completion({
                                action: 'submit',
                                data: {
                                    url: url,
                                    // Pass back the *new* values entered by the user.
                                    // The calling function will decide whether to update Keychain.
                                    token: newToken || null, // Send null if empty string
                                    openaiApiKey: newOpenaiApiKey || null // Send null if empty string
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
 * Generates HTML for the main text input form.
 * @param {string} [prefillText=''] - Text to pre-fill the textarea.
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
  // Only include the checkbox HTML if showAiOption is true
  const aiCheckboxHtml = showAiOption
    ? `
        <div class="options">
            <input type="checkbox" id="useAi" name="useAi">
            <label for="useAi">Process with AI (Generate Plan)</label>
        </div>
    `
    : ""; // Otherwise, include nothing

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

            ${aiCheckboxHtml} {/* This will be empty if showAiOption is false */}

            <button type="submit">Add Memo</button>
        </form>

        <script>
            // Function called by Scriptable to update the text area
            function updateTextArea(text) {
                const contentInput = document.getElementById('memoContent');
                if (contentInput && text != null) {
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
                    // IMPORTANT: useAiCheckbox might NOT exist if showAiOption was false
                    const useAiCheckbox = document.getElementById('useAi');
                    const pasteButton = document.getElementById('pasteButton');
                    const dictateButton = document.getElementById('dictateButton');

                    // Check only required elements
                    if (!form || !contentInput || !pasteButton || !dictateButton) {
                        console.error("Required form elements not found during initialization.");
                        alert("Error initializing form elements.");
                        if (typeof completion === 'function') completion({ error: "Initialization failed: Elements missing" });
                        return;
                    }

                    // Submit Handler
                    form.addEventListener('submit', (event) => {
                        event.preventDefault();
                        const content = contentInput.value.trim();
                        // Default to false if checkbox doesn't exist
                        const processWithAi = useAiCheckbox ? useAiCheckbox.checked : false;

                        if (content) {
                             if (typeof completion === 'function') {
                                completion({
                                    action: 'submit',
                                    data: {
                                        text: content,
                                        useAi: processWithAi // Will be false if checkbox wasn't shown
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

                    // Paste Button Handler
                    pasteButton.addEventListener('click', () => {
                        console.log("Paste button clicked.");
                        if (typeof completion === 'function') {
                            completion({ action: 'paste' });
                        } else {
                            console.error('CRITICAL: completion function unexpectedly not available for paste!');
                            alert('Error: Cannot request paste due to internal issue.');
                        }
                    });

                    // Dictate Button Handler
                    dictateButton.addEventListener('click', () => {
                        console.log("Dictate button clicked.");
                        if (typeof completion === 'function') {
                            completion({ action: 'dictate' });
                        } else {
                            console.error('CRITICAL: completion function unexpectedly not available for dictate!');
                            alert('Error: Cannot request dictation due to internal issue.');
                        }
                    });

                     contentInput.focus(); // Auto-focus
                     console.log("Input form initialized with Paste/Dictate listeners and focused.");

                } catch (initError) {
                    console.error("Error during input form initialization:", initError);
                    alert("A critical error occurred setting up the input form.");
                    if (typeof completion === 'function') completion({ error: "Initialization crashed", details: initError.message });
                }
            }
             // Do NOT call initializeForm() here directly.
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
  // (Keep the existing generatePlanReviewHtml function content as it was correct)
  // ... (same CSS and HTML generation logic as in your provided script) ...
   const css = `
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; padding: 15px; background-color: #f8f8f8; color: #333; }
        .plan-description { margin-bottom: 20px; padding: 10px; background-color: #eef; border-radius: 5px; border: 1px solid #dde; white-space: pre-wrap; }
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
           // Display complexity if present
          if (change.complexity !== null && change.complexity !== undefined) {
             changesHtml += `<div><strong>Complexity:</strong> ${escapeHtml(String(change.complexity))}</div>`;
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
    ? `<div class="plan-description"><strong>Plan:</strong>\n${escapeHtml( // Added newline for pre-wrap
        parsedPlanData.planText
      )}</div>`
    : "<p>No overall plan description provided.</p>";

   const chatNameHtml = parsedPlanData.chatName
    ? `<h3>${escapeHtml(parsedPlanData.chatName)}</h3>`
    : "";


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
        ${chatNameHtml}
        <p>Review the plan generated by the AI. Choose whether to use this plan for the memo comment.</p>

        ${planDescriptionHtml}
        ${filesHtml}

        <div class="button-group">
            <button id="usePlan">Use This Plan</button>
            <button id="useOriginal" class="secondary">Use Original Text</button>
        </div>

        <script>
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
                            completion({ action: 'submit', data: { confirmedPlan: true } });
                         } else { console.error('CRITICAL: completion function unexpectedly not available!'); alert('Error submitting choice.'); }
                    });

                    useOriginalButton.addEventListener('click', () => {
                         if (typeof completion === 'function') {
                            completion({ action: 'submit', data: { confirmedPlan: false } });
                         } else { console.error('CRITICAL: completion function unexpectedly not available!'); alert('Error submitting choice.'); }
                    });
                    console.log("AI Plan Review form initialized.");
                } catch (initError) {
                    console.error("Error during AI plan review form initialization:", initError);
                    alert("A critical error occurred setting up the AI plan review form.");
                    if (typeof completion === 'function') completion({ error: "Initialization crashed", details: initError.message });
                }
            }
             // Do NOT call initializeForm() here directly.
        </script>
    </body>
    </html>
    `;
}

/**
 * Retrieves Memos configuration (URL, Token, OpenAI Key) from Keychain.
 * Prompts the user using a WebView form if Memos URL or Token is missing,
 * or if explicitly requested via resetConfig.
 * @param {boolean} forcePrompt - If true, always show the config form.
 * @returns {Promise<{url: string, token: string, openaiApiKey: string|null}|null>} Configuration object, or null if cancelled/failed.
 * @throws {Error} If configuration cannot be obtained and user cancels/fails prompt.
 */
async function getConfig(forcePrompt = false) {
  console.log("Attempting to retrieve configuration from Keychain...");
  let url = Keychain.contains(KEYCHAIN_URL_KEY)
    ? Keychain.get(KEYCHAIN_URL_KEY)
    : null;
  console.log(`Retrieved Memos URL: ${url ? 'Exists' : 'Not Found'}`);

  let token = Keychain.contains(KEYCHAIN_TOKEN_KEY)
    ? Keychain.get(KEYCHAIN_TOKEN_KEY)
    : null;
   console.log(`Retrieved Memos Token: ${token ? 'Exists' : 'Not Found'}`);

  let openaiApiKey = Keychain.contains(KEYCHAIN_OPENAI_KEY)
    ? Keychain.get(KEYCHAIN_OPENAI_KEY)
    : null;
  // Add detailed logging for OpenAI key retrieval
  console.log(`Retrieved OpenAI Key from Keychain: ${openaiApiKey ? `Exists (Length: ${openaiApiKey.length})` : 'Not Found or Empty'}`);

  // --- Validation and Cleanup ---
  let needsSave = false; // Flag if changes require saving back to Keychain

  // Validate URL format
  if (url && !url.toLowerCase().startsWith("http")) {
    console.warn(`Invalid URL format stored: ${url}. Clearing.`);
    Keychain.remove(KEYCHAIN_URL_KEY);
    url = null;
    needsSave = true; // Need to prompt or fail
  }

  // Clean up potentially empty stored OpenAI key
  if (openaiApiKey !== null && openaiApiKey.trim() === "") {
     console.warn("Stored OpenAI Key was empty string. Clearing.");
     openaiApiKey = null;
     if (Keychain.contains(KEYCHAIN_OPENAI_KEY)) {
       Keychain.remove(KEYCHAIN_OPENAI_KEY);
     }
     // No need to set needsSave=true here, as missing key is handled below
  }
   console.log(`OpenAI Key after cleanup: ${openaiApiKey ? 'Exists' : 'null'}`);


  // --- Prompting Logic ---
  // Prompt if Memos URL or Token is missing OR if forcePrompt is true.
  if (forcePrompt || !url || !token) {
    console.log(
      `Configuration prompt needed. Reason: ${forcePrompt ? 'Forced' : (!url ? 'Memos URL missing' : 'Memos Token missing')}`
    );

    // Pass existing values to the form generator
    const configHtml = generateConfigFormHtml(url, token, openaiApiKey);
    const result = await presentWebViewForm(configHtml, false);

    if (!result) {
      console.log("Configuration prompt cancelled by user.");
      throw new Error("Configuration cancelled. Memos URL and Token are required.");
    }

    // --- Process Form Results ---
    const newUrl = result.url; // URL is always required from form
    const newToken = result.token; // Might be null if user left blank
    const newOpenaiApiKey = result.openaiApiKey; // Might be null if user left blank

    // Validate URL from form
    if (!newUrl || (!newUrl.toLowerCase().startsWith('http://') && !newUrl.toLowerCase().startsWith('https://'))) {
        throw new Error("Invalid Memos URL provided in form.");
    }
    url = newUrl; // Update URL
    Keychain.set(KEYCHAIN_URL_KEY, url);
    console.log("Saved Memos URL.");
    needsSave = false; // Reset flag as we just saved

    // Update Token only if a *new* value was provided
    if (newToken) {
        token = newToken;
        Keychain.set(KEYCHAIN_TOKEN_KEY, token);
        console.log("Saved new Memos Token.");
    } else if (!token) {
        // If no new token was provided AND no token existed before, it's an error.
        throw new Error("Memos Access Token is required but was not provided.");
    } else {
         console.log("Memos Token field left blank, keeping existing token.");
    }

    // Update OpenAI Key: Save if new value provided, remove if blanked, keep if existed & left blank
    if (newOpenaiApiKey) {
        openaiApiKey = newOpenaiApiKey;
        Keychain.set(KEYCHAIN_OPENAI_KEY, openaiApiKey);
        console.log("Saved new OpenAI API Key.");
    } else if (openaiApiKey && !newOpenaiApiKey) {
        // User explicitly cleared the field (submitted null/empty) while a key existed
        console.log("OpenAI Key field left blank, removing existing key.");
        openaiApiKey = null;
        if (Keychain.contains(KEYCHAIN_OPENAI_KEY)) {
            Keychain.remove(KEYCHAIN_OPENAI_KEY);
        }
    } else if (!openaiApiKey && !newOpenaiApiKey) {
         console.log("No OpenAI API Key provided or previously saved.");
         openaiApiKey = null; // Ensure it's null
    } else {
        // Key existed, user left blank -> keep existing (openaiApiKey already holds it)
         console.log("OpenAI Key field left blank, keeping existing key.");
    }

    console.log("Configuration processing complete.");

  } else {
    console.log("Configuration retrieved successfully from Keychain without prompt.");
    // If we performed cleanup earlier but didn't prompt, save might still be needed
    // (Though current cleanup logic doesn't require this path)
    // if (needsSave) { /* ... potentially save cleaned values ... */ }
  }

  // Final check: Ensure we have URL and Token before returning
  if (!url || !token) {
      throw new Error("Configuration incomplete: Missing Memos URL or Token after processing.");
  }

  console.log(`FINAL Config Check - URL: ${!!url}, Token: ${!!token}, OpenAI Key: ${!!openaiApiKey}`);
  return { url, token, openaiApiKey };
}


/**
 * Gets text input from Share Sheet or WebView form.
 * @param {boolean} allowAiOption - Whether to include the AI processing option in the form.
 * @returns {Promise<{text: string, useAi: boolean}|null>} Object with input text and AI choice, or null if cancelled/empty.
 */
async function getInputText(allowAiOption = false) {
  console.log("Checking for input source...");
  let initialText = "";

  if (args.plainTexts && args.plainTexts.length > 0) {
    const sharedText = args.plainTexts.join("\n").trim();
    if (sharedText) {
      console.log("Using text from Share Sheet.");
      initialText = sharedText;
    }
  } else {
    console.log("No Share Sheet input found.");
  }

  console.log(`Presenting WebView form for text input. Show AI Option: ${allowAiOption}`);
  const inputHtml = generateInputFormHtml(initialText, allowAiOption);
  const formData = await presentWebViewForm(inputHtml, false);

  if (!formData || typeof formData.text === "undefined" || typeof formData.useAi === "undefined") {
    console.log("Input cancelled or form did not return expected data.");
    return null;
  }
  if (formData.text.trim() === "") {
    console.log("No text entered.");
    return null;
  }

  console.log(`Input received. Use AI checkbox state: ${formData.useAi}`);
  // Ensure useAi is false if the option wasn't allowed/shown
  const finalUseAi = allowAiOption ? formData.useAi : false;
  console.log(`Final 'useAi' decision: ${finalUseAi}`);

  return { text: formData.text.trim(), useAi: finalUseAi };
}

/**
 * Makes an authenticated request to an API (Memos or OpenAI).
 * @param {string} url - The full API endpoint URL.
 * @param {string} method - HTTP method (e.g., "GET", "POST").
 * @param {object} headers - Request headers object.
 * @param {object|null} body - The request body object (will be JSON.stringify'd).
 * @param {number} [timeout=60] - Timeout in seconds.
 * @param {string} [serviceName="API"] - Name for logging (e.g., "Memos", "OpenAI").
 * @returns {Promise<any>} The JSON response or raw string response.
 * @throws {Error} If the API request fails or returns a non-2xx status code.
 */
async function makeApiRequest(url, method, headers, body = null, timeout = 60, serviceName = "API") {
  console.log(`Making ${serviceName} request: ${method} ${url}`);
  const req = new Request(url);
  req.method = method;
  req.headers = headers;
  req.timeoutInterval = timeout;
  req.allowInsecureRequest = url.startsWith("http://"); // Allow insecure for http only

  if (body) {
    req.body = JSON.stringify(body);
    // Avoid logging potentially sensitive bodies like OpenAI requests fully
    console.log(`${serviceName} Request body: ${body.content ? `{"content": "[CENSORED, Length: ${body.content.length}]", ...}` : (body.messages ? `{"messages": "[CENSORED]", ...}`: JSON.stringify(body).substring(0, 100) + "...")}`);
  }

  try {
    let responseData;
    let statusCode;
    let responseText = "";

    // Determine if we expect JSON based on Content-Type or common practice
    const expectJson = headers["Content-Type"]?.includes("json") || headers["Accept"]?.includes("json");

    if (expectJson && method.toUpperCase() !== 'GET') { // POST/etc expecting JSON
        responseData = await req.loadJSON();
        statusCode = req.response.statusCode;
        responseText = JSON.stringify(responseData); // For error logging if needed
    } else if (method.toUpperCase() === 'GET') { // GET usually expects JSON
         responseData = await req.loadJSON();
         statusCode = req.response.statusCode;
    }
     else { // Load as string for non-GET or non-JSON expecting requests
      responseText = await req.loadString();
      statusCode = req.response.statusCode;
      // Try to parse as JSON if responseText is not empty and looks like JSON
       try {
           responseData = responseText && responseText.trim().startsWith('{') ? JSON.parse(responseText) : responseText;
       } catch (parseError) {
           console.warn(`${serviceName} response was not valid JSON, returning as string.`);
           responseData = responseText; // Return raw string if parsing fails
       }
    }

    console.log(`${serviceName} Response Status Code: ${statusCode}`);
    if (statusCode < 200 || statusCode >= 300) {
      console.error(`${serviceName} Error Response Text: ${responseText}`);
      // Try to extract a message from JSON error response
      let errorMessage = responseText;
      if (typeof responseData === 'object' && responseData !== null) {
          errorMessage = responseData.error?.message || responseData.message || JSON.stringify(responseData);
      }
      throw new Error(`${serviceName} Error ${statusCode}: ${errorMessage || "Unknown error"}`);
    }

    console.log(`${serviceName} request successful.`);
    return responseData; // Return parsed JSON or raw string
  } catch (e) {
    // Don't re-wrap errors we already threw
    if (e.message.startsWith(`${serviceName} Error`)) {
        throw e;
    }
    console.error(`${serviceName} Request Failed: ${method} ${url} - ${e}`);
    // Check if the error is from JSON parsing or the request itself
    if (e instanceof SyntaxError) {
      throw new Error(
        `${serviceName} Error: Failed to parse JSON response. Status: ${req.response?.statusCode}. Response: ${responseText}`
      );
    } else {
      throw new Error(`${serviceName} Request Failed: ${e.message || e}`); // Re-throw original network or status code error
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
  const endpoint = config.url.replace(/\/$/, "") + "/api/v1/memos";
  const headers = {
    "Content-Type": "application/json",
    Authorization: `Bearer ${config.token}`,
  };
  const body = {
    content: title,
    visibility: "PRIVATE", // Or make configurable: "PUBLIC", "PROTECTED"
  };
  console.log(`Creating memo with title: "${title}"`);
  return await makeApiRequest(endpoint, "POST", headers, body, 30, "Memos");
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
  const model = "gpt-4o"; // Or "gpt-3.5-turbo", "gpt-4-turbo"

  // Define the XML formatting instructions (Keep the existing instructions)
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

  const headers = {
    "Content-Type": "application/json",
    Authorization: `Bearer ${apiKey}`,
  };
  const body = {
    model: model,
    messages: messages,
    max_tokens: 3500, // Increased slightly
    temperature: 0.3,
    n: 1,
    stop: null,
  };

  try {
    const responseJson = await makeApiRequest(endpoint, "POST", headers, body, 90, "OpenAI"); // Use generalized function

    // Response from makeApiRequest should already be parsed JSON
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
      // Consider throwing error if strict XML is required
      // throw new Error("OpenAI response did not appear to be valid XML.");
    }
    return xmlContent;
  } catch (e) {
     // Catch errors specifically from OpenAI request
     console.error(`OpenAI Plan Generation Failed: ${e}`);
     throw new Error(`OpenAI Plan Generation Failed: ${e.message}`); // Re-throw with specific context
  }
}

/**
 * Parses the AI-generated XML plan into a JavaScript object.
 * @param {string} xmlString - The raw XML string from OpenAI.
 * @returns {object|null} Structured plan object or null on parsing error.
 */
function parseAiXmlResponse(xmlString) {
  // (Keep the existing parseAiXmlResponse function content as it was correct)
  // ... (same XMLParser logic as in your provided script) ...
   console.log("Parsing AI XML response...");
  // Add a check for empty input string
  if (!xmlString || typeof xmlString !== 'string' || xmlString.trim() === '') {
      console.error("Cannot parse empty or invalid XML string.");
      return null;
  }
  try {
    const parser = new XMLParser(xmlString);
    let parsedData = { chatName: "", planText: "", files: [] };
    let currentFile = null;
    let currentChange = null;
    let currentTag = null;
    let accumulatedChars = "";
    let parseError = null; // Store error details

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
          search: "", // Initialize search
        };
      }
    };

    parser.foundCharacters = (chars) => {
      // Only accumulate if we are inside a relevant tag
      if (currentTag) {
          accumulatedChars += chars;
      }
    };

    parser.didEndElement = (name) => {
      const tagName = name.toLowerCase();
      // Trim only when assigning final value
      const trimmedChars = accumulatedChars.trim();
      // console.log(`End Element: ${name}, Chars: "${trimmedChars}"`);

      if (tagName === "chatname") {
        parsedData.chatName = trimmedChars;
      } else if (tagName === "plan") {
        parsedData.planText = trimmedChars;
      } else if (tagName === "file") {
        if (currentFile) {
          // Ensure file has path and action before adding
          if (currentFile.path && currentFile.action) {
             parsedData.files.push(currentFile);
          } else {
             console.warn("Skipping file element missing path or action:", currentFile);
          }
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
      // Reset context AFTER processing the closing tag
      currentTag = null;
      accumulatedChars = "";
    };

    parser.parseErrorOccurred = (line, column, message) => {
      parseError = `XML Parse Error at ${line}:${column}: ${message}`;
      console.error(parseError);
      // Stop parsing immediately on fatal error
      return; // Or throw new Error(parseError); if you want parsing to halt execution flow
    };

    const success = parser.parse();

    if (!success || parseError) {
      console.error("XML parsing failed.", parseError || "");
      // Optionally throw the error to be caught by the caller
      // throw new Error(parseError || "XML parsing failed.");
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
  // (Keep the existing formatPlanForMemo function content as it was correct)
  // ... (same Markdown generation logic as in your provided script) ...
    if (!parsedPlanData) return "Error: Could not format plan (null data).";

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
          if (change.complexity !== null && change.complexity !== undefined) {
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
   const headers = {
    "Content-Type": "application/json",
    Authorization: `Bearer ${config.token}`,
  };
  const body = { content: commentText };
  console.log(`Adding comment to memo ID: ${memoId}`);
  return await makeApiRequest(endpoint, "POST", headers, body, 30, "Memos");
}

// --- Main Execution ---

(async () => {
  console.log(
    "Starting Interactive Quick Capture (with AI Plan) to Memos script..."
  );
  let forceConfigPrompt = false; // Flag to force showing the config screen

  // --- Configuration Reset Logic ---
  if (args.queryParameters && args.queryParameters.resetConfig === "true") {
    console.log("Reset configuration argument detected.");
    const confirmAlert = new Alert();
    confirmAlert.title = "Reset Configuration?";
    confirmAlert.message =
      "Are you sure you want to remove the saved Memos URL, Access Token, and OpenAI Key? You will be prompted to re-enter them.";
    confirmAlert.addAction("Reset");
    confirmAlert.addCancelAction("Cancel");
    const confirmation = await confirmAlert.presentAlert();
    if (confirmation === 0) {
      console.log("Removing configuration from Keychain...");
      if (Keychain.contains(KEYCHAIN_URL_KEY)) Keychain.remove(KEYCHAIN_URL_KEY);
      if (Keychain.contains(KEYCHAIN_TOKEN_KEY)) Keychain.remove(KEYCHAIN_TOKEN_KEY);
      if (Keychain.contains(KEYCHAIN_OPENAI_KEY)) Keychain.remove(KEYCHAIN_OPENAI_KEY);
      console.log("Configuration removed.");
      forceConfigPrompt = true; // Force the prompt after resetting
      // Optional: Show a success alert for reset
      // const successAlert = new Alert();
      // successAlert.title = "Configuration Reset";
      // successAlert.message = "Configuration removed. Please re-enter details.";
      // await successAlert.presentAlert();
    } else {
      console.log("Configuration reset cancelled.");
      Script.complete(); // Exit if reset is cancelled
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
    // Get config, forcing prompt if reset was performed
    config = await getConfig(forceConfigPrompt);
    console.log("Configuration obtained:", config ? `URL: ${!!config.url}, Token: ${!!config.token}, OpenAI Key: ${!!config.openaiApiKey}` : "Failed");

    // Explicitly check if a valid OpenAI key string exists in the config object
    const hasValidOpenAIKey = typeof config.openaiApiKey === 'string' && config.openaiApiKey.trim().length > 0;
    console.log(`Has valid OpenAI Key for showing option? ${hasValidOpenAIKey}`);

    // Pass the result of the check to getInputText
    inputData = await getInputText(hasValidOpenAIKey);

    if (!inputData) {
      console.log("No input text provided or cancelled. Exiting.");
      Script.complete();
      return;
    }

    originalInputText = inputData.text;
    // Use the 'useAi' value returned from getInputText, which respects whether the option was shown
    let processWithAi = inputData.useAi;
    finalText = originalInputText; // Default to original text

    console.log(`User wants to process with AI: ${processWithAi}`);

    // --- AI Plan Generation Flow ---
    // Check both the user's choice AND if we actually have a key
    if (processWithAi && hasValidOpenAIKey) {
      console.log("Proceeding with AI plan generation...");
      let processingAlert = null;
      try {
        processingAlert = new Alert();
        processingAlert.title = "Generating AI Plan...";
        processingAlert.message = "Please wait.";
        processingAlert.present(); // Show non-blocking alert

        const rawXml = await getAiPlanAsXml(
          config.openaiApiKey, // We know this is valid here
          originalInputText
        );

        // Dismiss alert *before* parsing, as parsing can be quick
        if (processingAlert && typeof processingAlert.dismiss === "function") {
          try { processingAlert.dismiss(); } catch (e) { console.warn("Could not dismiss processing alert:", e); }
        }
        processingAlert = null;

        const parsedPlan = parseAiXmlResponse(rawXml);

        if (!parsedPlan) {
          // Throw error if parsing failed (parseAiXmlResponse returns null)
          throw new Error("Failed to parse the AI-generated XML plan. The response might not be valid XML.");
        }

        console.log("AI plan parsed successfully. Asking for review via WebView.");
        const reviewHtml = generatePlanReviewHtml(parsedPlan);
        const reviewResult = await presentWebViewForm(reviewHtml, true); // Present fullscreen for review

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
          console.log("AI plan review cancelled or failed. Reverting to original text.");
        }
      } catch (aiError) {
         // Ensure alert is dismissed if error occurred during API call or parsing
         if (processingAlert && typeof processingAlert.dismiss === "function") {
           try { processingAlert.dismiss(); } catch (e) { console.warn("Could not dismiss processing alert:", e); }
         }
        console.error(`AI Plan Generation/Processing Failed: ${aiError}`);

        const aiErrorAlert = new Alert();
        aiErrorAlert.title = "AI Plan Error";
        aiErrorAlert.message = `Failed to generate or process AI plan:\n${aiError.message}\n\nUse original text instead?`;
        aiErrorAlert.addAction("Use Original");
        aiErrorAlert.addCancelAction("Cancel Script");
        const errorChoice = await aiErrorAlert.presentAlert();

        if (errorChoice === -1) { // Cancelled
          console.log("Script cancelled due to AI plan processing error.");
          Script.complete();
          return;
        }
        finalText = originalInputText; // Use original on error confirmation
        console.log("Proceeding with original text after AI error.");
      }
    } else {
      // Log reasons for skipping AI plan generation
      if (!hasValidOpenAIKey) {
          console.log("Skipping AI plan: No valid OpenAI API Key configured.");
      } else if (!processWithAi) {
          console.log("Skipping AI plan: User did not select AI processing checkbox.");
      }
      finalText = originalInputText; // Ensure final text is set if AI wasn't used
    }
    // --- End AI Plan Generation Flow ---

    // --- Memos Creation ---
    console.log("Proceeding to create Memos entry...");
    const memoTitle = `Quick Capture - ${new Date().toLocaleString()}`;
    createdMemo = await createMemo(config, memoTitle);

    // Extract ID from name like "memos/101" -> "101" or the newer format "memos/users/1/memos/101" -> "101"
    const nameParts = createdMemo?.name?.split('/');
    memoId = nameParts ? nameParts[nameParts.length - 1] : null;

    if (!memoId || !/^\d+$/.test(memoId)) { // Check if memoId is numeric after extraction
      console.error("Failed to get valid numeric memo ID from creation response.", createdMemo);
      throw new Error(`Could not determine the new memo's numeric ID from name: ${createdMemo?.name}`);
    }
    console.log(`Memo created successfully with ID: ${memoId}`);

    await addCommentToMemo(config, memoId, finalText);
    console.log("Comment added successfully!");

    // --- Success Alert ---
    let showAlerts = !(typeof args.runsInWidget === "boolean" && args.runsInWidget);
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
    // --- Error Alert ---
    let showAlerts = !(typeof args.runsInWidget === "boolean" && args.runsInWidget);
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
         } else if (e.message.includes("404") && e.message.toLowerCase().includes("memos")) {
           errorAlert.message += "\n\nCheck Memos URL Path.";
         } else if (e.message.includes("ENOTFOUND") || e.message.includes("Could not connect") || e.message.includes("timed out")) {
           errorAlert.message += "\n\nCheck Network/URL Reachability.";
         } else if (e.message.toLowerCase().includes("openai") && e.message.toLowerCase().includes("quota")) {
           errorAlert.message += "\n\nCheck OpenAI Quota.";
         } else if (e.message.toLowerCase().includes("xml parse error") || e.message.toLowerCase().includes("valid xml")) {
           errorAlert.message += "\n\nAI response was not valid XML.";
         } else if (e.message.includes("Configuration incomplete") || e.message.includes("Configuration cancelled")) {
            errorAlert.message += "\n\nPlease ensure Memos URL and Token are configured correctly.";
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
