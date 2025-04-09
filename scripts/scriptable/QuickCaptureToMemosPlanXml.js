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
    .replace(/"/g, '"')
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
          resolve(new Promise(() => {})); // A promise that never resolves on its own
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
            return result.data; // Final submission data

          case "paste":
            console.log(
              "WebView Loop: Received 'paste' action. Getting clipboard..."
            );
            const clipboardText = Pasteboard.pasteString() || "";
            console.log(`Clipboard content length: ${clipboardText.length}`);
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
            }
            break; // Go to next iteration of the while loop

          case "dictate":
            console.log(
              "WebView Loop: Received 'dictate' action. Starting dictation..."
            );
            try {
              const dictatedText = await Dictation.start();
              console.log(
                `Dictation result length: ${
                  dictatedText ? dictatedText.length : "null"
                }`
              );
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
                let fallbackAlert = new Alert();
                fallbackAlert.title = "Dictation Error";
                fallbackAlert.message = `Dictation failed: ${dictationError.message}`;
                await fallbackAlert.presentAlert();
              }
            }
            break; // Go to next iteration of the while loop

          default:
            console.warn(
              `WebView Loop: Received unknown action: ${result.action}`
            );
            break;
        }
      } else {
        console.warn(
          "WebView Loop: evaluatePromise resolved with unexpected result:",
          result
        );
      }
    } // End while loop
  } catch (e) {
    console.error(`Error during interactive WebView operation: ${e}`);
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
  // (Keep the existing generateConfigFormHtml function content as it was correct)
  // ... (same CSS and HTML generation logic as in the previous version) ...
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

  const urlValue = existingUrl ? `value="${escapeHtml(existingUrl)}"` : "";
  const tokenPlaceholder = existingToken
    ? `placeholder="Exists (Enter new to change)"`
    : `placeholder="Enter Memos Token"`;
  const openaiKeyPlaceholder = existingOpenAIKey
    ? `placeholder="Exists (Enter new to change)"`
    : `placeholder="Enter OpenAI Key (Optional)"`;

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
                    event.preventDefault();
                    urlError.style.display = 'none';
                    tokenError.style.display = 'none';
                    let isValid = true;

                    const url = urlInput.value.trim();
                    const newToken = tokenInput.value.trim();
                    const newOpenaiApiKey = openaiInput.value.trim();

                    if (!url) {
                        urlError.textContent = 'Memos URL is required.';
                        urlError.style.display = 'block';
                        isValid = false;
                    } else if (!url.toLowerCase().startsWith('http://') && !url.toLowerCase().startsWith('https://')) {
                        urlError.textContent = 'URL must start with http:// or https://';
                        urlError.style.display = 'block';
                        isValid = false;
                    }

                    if (isValid) {
                        if (typeof completion === 'function') {
                            completion({
                                action: 'submit',
                                data: {
                                    url: url,
                                    token: newToken || null,
                                    openaiApiKey: newOpenaiApiKey || null
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
        // Do NOT call initializeForm() here directly.
        </script>
    </body>
    </html>
    `;
}

/**
 * Generates HTML for the main text input form (AI checkbox removed).
 * @param {string} [prefillText=''] - Text to pre-fill the textarea.
 * @returns {string} HTML content for the input form.
 */
function generateInputFormHtml(prefillText = "") {
  const css = `
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; padding: 15px; display: flex; flex-direction: column; height: 95vh; background-color: #f8f8f8; color: #333; }
        textarea { flex-grow: 1; width: 95%; padding: 10px; margin-bottom: 15px; border: 1px solid #ccc; border-radius: 8px; font-size: 16px; resize: none; }
        .button-bar { display: flex; gap: 10px; margin-bottom: 15px; }
        .button-bar button { flex-grow: 1; padding: 10px 15px; background-color: #e0e0e0; color: #333; border: 1px solid #ccc; border-radius: 8px; cursor: pointer; font-size: 14px; }
        .button-bar button:hover { background-color: #d0d0d0; }
        button[type=submit] { padding: 12px 20px; background-color: #007aff; color: white; border: none; border-radius: 8px; cursor: pointer; font-size: 16px; width: 100%; margin-top: auto; }
        button[type=submit]:hover { background-color: #0056b3; }
        /* Removed .options CSS */
        h2 { margin-top: 0; color: #111; }
        .clipboard-notice { font-size: 0.9em; color: #666; margin-bottom: 10px; }
        form { display: flex; flex-direction: column; flex-grow: 1; }
    `;

  const shareSheetNotice = prefillText
    ? '<div class="clipboard-notice">Text pre-filled from Share Sheet.</div>'
    : "";
  // AI Checkbox HTML is completely removed

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

            {/* AI Checkbox removed from here */}

            <button type="submit">Add Memo</button>
        </form>

        <script>
            function updateTextArea(text) {
                const contentInput = document.getElementById('memoContent');
                if (contentInput && text != null) {
                    const currentText = contentInput.value;
                    contentInput.value = currentText ? currentText + " " + text : text;
                    contentInput.focus();
                    console.log("Text area updated.");
                } else {
                    console.error("Could not find text area or text was null.");
                }
            }

            function initializeForm() {
                try {
                    const form = document.getElementById('inputForm');
                    const contentInput = document.getElementById('memoContent');
                    // useAiCheckbox is removed
                    const pasteButton = document.getElementById('pasteButton');
                    const dictateButton = document.getElementById('dictateButton');

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
                        // processWithAi is removed from here

                        if (content) {
                             if (typeof completion === 'function') {
                                completion({
                                    action: 'submit',
                                    data: {
                                        text: content
                                        // useAi property removed
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

                     contentInput.focus();
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
  // ... (same CSS and HTML generation logic as in the previous version) ...
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
        h2, h3 { margin-top: 0; color: #111; }
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
          if (
            change.search &&
            (file.action === "delegate edit" || file.action === "modify")
          ) {
            changesHtml += `<div><strong>Search/Context:</strong><pre class="code-block search">${escapeHtml(
              change.search
            )}</pre></div>`;
          }
          if (change.content && file.action !== "delete") {
            changesHtml += `<div><strong>Content/Change:</strong><pre class="code-block content">${escapeHtml(
              change.content
            )}</pre></div>`;
          }
          if (file.action === "delete") {
            changesHtml += `<pre class="code-block delete">(File to be deleted)</pre>`;
          }
          if (change.complexity !== null && change.complexity !== undefined) {
            changesHtml += `<div><strong>Complexity:</strong> ${escapeHtml(
              String(change.complexity)
            )}</div>`;
          }
          changesHtml += `</div>`;
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
    ? `<div class="plan-description"><strong>Plan:</strong>\n${escapeHtml(
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
  console.log(`Retrieved Memos URL: ${url ? "Exists" : "Not Found"}`);

  let token = Keychain.contains(KEYCHAIN_TOKEN_KEY)
    ? Keychain.get(KEYCHAIN_TOKEN_KEY)
    : null;
  console.log(`Retrieved Memos Token: ${token ? "Exists" : "Not Found"}`);

  let openaiApiKey = Keychain.contains(KEYCHAIN_OPENAI_KEY)
    ? Keychain.get(KEYCHAIN_OPENAI_KEY)
    : null;
  console.log(
    `Retrieved OpenAI Key from Keychain: ${
      openaiApiKey
        ? `Exists (Length: ${openaiApiKey.length})`
        : "Not Found or Empty"
    }`
  );

  // --- Validation and Cleanup ---
  let needsSave = false; // Flag if changes require saving back to Keychain

  if (url && !url.toLowerCase().startsWith("http")) {
    console.warn(`Invalid URL format stored: ${url}. Clearing.`);
    Keychain.remove(KEYCHAIN_URL_KEY);
    url = null;
    needsSave = true; // Need to prompt or fail
  }

  if (openaiApiKey !== null && openaiApiKey.trim() === "") {
    console.warn("Stored OpenAI Key was empty string. Clearing.");
    openaiApiKey = null;
    if (Keychain.contains(KEYCHAIN_OPENAI_KEY)) {
      Keychain.remove(KEYCHAIN_OPENAI_KEY);
    }
  }
  console.log(`OpenAI Key after cleanup: ${openaiApiKey ? "Exists" : "null"}`);

  // --- Prompting Logic ---
  if (forcePrompt || !url || !token) {
    console.log(
      `Configuration prompt needed. Reason: ${
        forcePrompt
          ? "Forced Reset"
          : !url
          ? "Memos URL missing"
          : "Memos Token missing"
      }`
    );

    const configHtml = generateConfigFormHtml(url, token, openaiApiKey);
    const result = await presentWebViewForm(configHtml, false);

    if (!result) {
      console.log("Configuration prompt cancelled by user.");
      throw new Error(
        "Configuration cancelled. Memos URL and Token are required."
      );
    }

    // --- Process Form Results ---
    const newUrl = result.url;
    const newToken = result.token;
    const newOpenaiApiKey = result.openaiApiKey; // This is the value from the form field

    console.log(
      `Form submitted - URL: ${newUrl}, NewTokenProvided: ${!!newToken}, NewOpenAIKeyProvided: ${!!newOpenaiApiKey} (Length: ${
        newOpenaiApiKey?.length ?? 0
      })`
    );

    if (
      !newUrl ||
      (!newUrl.toLowerCase().startsWith("http://") &&
        !newUrl.toLowerCase().startsWith("https://"))
    ) {
      throw new Error("Invalid Memos URL provided in form.");
    }
    // Save URL unconditionally if form was shown
    url = newUrl;
    Keychain.set(KEYCHAIN_URL_KEY, url);
    console.log("Saved Memos URL.");
    needsSave = false;

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

    // Update OpenAI Key logic:
    if (newOpenaiApiKey) {
      // User entered a new key
      openaiApiKey = newOpenaiApiKey;
      console.log(
        `Attempting to save NEW OpenAI Key to Keychain (length: ${openaiApiKey.length})...`
      );
      Keychain.set(KEYCHAIN_OPENAI_KEY, openaiApiKey);
      console.log("Saved new OpenAI API Key.");
    } else if (openaiApiKey && !newOpenaiApiKey) {
      // Key existed, but user submitted blank field -> Remove it
      console.log(
        "OpenAI Key field left blank, removing existing key from Keychain."
      );
      openaiApiKey = null;
      if (Keychain.contains(KEYCHAIN_OPENAI_KEY)) {
        Keychain.remove(KEYCHAIN_OPENAI_KEY);
      }
    } else if (!openaiApiKey && !newOpenaiApiKey) {
      // No key existed, none provided -> Ensure it's null
      console.log("No OpenAI API Key provided or previously saved.");
      openaiApiKey = null;
    } else {
      // Key existed, user left blank -> Keep existing
      console.log(
        "OpenAI Key field left blank, keeping existing key (no change to Keychain)."
      );
      // openaiApiKey already holds the existing value
    }

    console.log("Configuration processing complete after prompt.");
  } else {
    console.log(
      "Configuration retrieved successfully from Keychain without prompt."
    );
  }

  // Final check: Ensure we have URL and Token before returning
  if (!url || !token) {
    throw new Error(
      "Configuration incomplete: Missing Memos URL or Token after processing."
    );
  }

  console.log(
    `FINAL Config Check - URL: ${!!url}, Token: ${!!token}, OpenAI Key: ${
      openaiApiKey ? `Exists (Length: ${openaiApiKey.length})` : "null"
    }`
  );
  return { url, token, openaiApiKey };
}

/**
 * Gets text input from Share Sheet or WebView form. (AI option removed)
 * @returns {Promise<string|null>} Input text string, or null if cancelled/empty.
 */
async function getInputText() {
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

  console.log(`Presenting WebView form for text input (AI option removed).`);
  // Call generateInputFormHtml without the second argument
  const inputHtml = generateInputFormHtml(initialText);
  const formData = await presentWebViewForm(inputHtml, false);

  // formData should now only contain { text: "..." } on success
  if (!formData || typeof formData.text === "undefined") {
    console.log("Input cancelled or form did not return text data.");
    return null;
  }
  if (formData.text.trim() === "") {
    console.log("No text entered.");
    return null;
  }

  console.log(`Input text received.`);
  return formData.text.trim(); // Return only the text string
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
async function makeApiRequest(
  url,
  method,
  headers,
  body = null,
  timeout = 60,
  serviceName = "API"
) {
  // (Keep the existing makeApiRequest function content as it was correct)
  // ... (same Request logic as in the previous version) ...
  console.log(`Making ${serviceName} request: ${method} ${url}`);
  const req = new Request(url);
  req.method = method;
  req.headers = headers;
  req.timeoutInterval = timeout;
  req.allowInsecureRequest = url.startsWith("http://");

  if (body) {
    req.body = JSON.stringify(body);
    console.log(
      `${serviceName} Request body: ${
        body.content
          ? `{"content": "[CENSORED, Length: ${body.content.length}]", ...}`
          : body.messages
          ? `{"messages": "[CENSORED]", ...}`
          : JSON.stringify(body).substring(0, 100) + "..."
      }`
    );
  }

  try {
    let responseData;
    let statusCode;
    let responseText = "";

    const expectJson =
      headers["Content-Type"]?.includes("json") ||
      headers["Accept"]?.includes("json");

    // Use loadJSON for GET or if JSON is expected for POST/etc.
    if (method.toUpperCase() === "GET" || expectJson) {
      try {
        responseData = await req.loadJSON();
        statusCode = req.response.statusCode;
        responseText = JSON.stringify(responseData); // For potential error logging
      } catch (e) {
        // If loadJSON fails (e.g., empty response, non-JSON), try loadString
        console.warn(
          `${serviceName} loadJSON failed (Status: ${req.response?.statusCode}), trying loadString. Error: ${e.message}`
        );
        statusCode = req.response?.statusCode ?? 500; // Get status code if available
        if (statusCode >= 200 && statusCode < 300) {
          // If status was OK but response wasn't JSON
          responseText = await req.loadString();
          responseData = responseText; // Treat as string response
          console.log(
            `${serviceName} received non-JSON success response (Status: ${statusCode}).`
          );
        } else {
          // If status code indicates error, load string for error message
          responseText = await req.loadString().catch(() => ""); // Try to get error body
          responseData = responseText; // Keep error body as string
          console.error(
            `${serviceName} loadJSON failed and status code ${statusCode} indicates error.`
          );
          // Let the status code check below handle throwing the error
        }
      }
    } else {
      // Load as string for non-JSON expecting requests
      responseText = await req.loadString();
      statusCode = req.response.statusCode;
      responseData = responseText;
    }

    console.log(`${serviceName} Response Status Code: ${statusCode}`);
    if (statusCode < 200 || statusCode >= 300) {
      console.error(`${serviceName} Error Response Body: ${responseText}`);
      let errorMessage = responseText;
      // Try to extract message if responseData happened to be parsed JSON error
      if (typeof responseData === "object" && responseData !== null) {
        errorMessage =
          responseData.error?.message ||
          responseData.message ||
          JSON.stringify(responseData);
      }
      throw new Error(
        `${serviceName} Error ${statusCode}: ${errorMessage || "Unknown error"}`
      );
    }

    console.log(`${serviceName} request successful.`);
    return responseData;
  } catch (e) {
    if (e.message.startsWith(`${serviceName} Error`)) {
      throw e;
    }
    console.error(`${serviceName} Request Failed: ${method} ${url} - ${e}`);
    throw new Error(`${serviceName} Request Failed: ${e.message || e}`);
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
  // (Keep the existing createMemo function content as it was correct)
  // ... (same logic using makeApiRequest) ...
  const endpoint = config.url.replace(/\/$/, "") + "/api/v1/memos";
  const headers = {
    "Content-Type": "application/json",
    Authorization: `Bearer ${config.token}`,
  };
  const body = {
    content: title,
    visibility: "PRIVATE",
  };
  console.log(`Creating memo with title: "${title}"`);
  // Expects JSON response
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
  // (Keep the existing getAiPlanAsXml function content as it was correct)
  // ... (same logic using makeApiRequest, including XML instructions) ...
  console.log("Requesting XML plan from OpenAI...");
  const endpoint = "https://api.openai.com/v1/chat/completions";
  const model = "gpt-4o";

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
    max_tokens: 3500,
    temperature: 0.3,
    n: 1,
    stop: null,
  };

  try {
    // Expects JSON response
    const responseJson = await makeApiRequest(
      endpoint,
      "POST",
      headers,
      body,
      90,
      "OpenAI"
    );

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
    if (!xmlContent.startsWith("<") || !xmlContent.endsWith(">")) {
      console.warn("OpenAI response doesn't look like XML:", xmlContent);
    }
    return xmlContent;
  } catch (e) {
    console.error(`OpenAI Plan Generation Failed: ${e}`);
    throw new Error(`OpenAI Plan Generation Failed: ${e.message}`);
  }
}

/**
 * Parses the AI-generated XML plan into a JavaScript object.
 * @param {string} xmlString - The raw XML string from OpenAI.
 * @returns {object|null} Structured plan object or null on parsing error.
 */
function parseAiXmlResponse(xmlString) {
  // (Keep the existing parseAiXmlResponse function content as it was correct)
  // ... (same XMLParser logic as in the previous version) ...
  console.log("Parsing AI XML response...");
  if (!xmlString || typeof xmlString !== "string" || xmlString.trim() === "") {
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
    let parseError = null;

    parser.didStartElement = (name, attrs) => {
      currentTag = name.toLowerCase();
      accumulatedChars = "";
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
          complexity: null,
          search: "",
        };
      }
    };

    parser.foundCharacters = (chars) => {
      if (currentTag) {
        accumulatedChars += chars;
      }
    };

    parser.didEndElement = (name) => {
      const tagName = name.toLowerCase();
      const trimmedChars = accumulatedChars.trim();

      if (tagName === "chatname") {
        parsedData.chatName = trimmedChars;
      } else if (tagName === "plan") {
        parsedData.planText = trimmedChars;
      } else if (tagName === "file") {
        if (currentFile) {
          if (currentFile.path && currentFile.action) {
            parsedData.files.push(currentFile);
          } else {
            console.warn(
              "Skipping file element missing path or action:",
              currentFile
            );
          }
          currentFile = null;
        }
      } else if (tagName === "change") {
        if (currentChange && currentFile) {
          currentFile.changes.push(currentChange);
          currentChange = null;
        }
      } else if (currentChange) {
        if (tagName === "description") {
          currentChange.description = trimmedChars;
        } else if (tagName === "content") {
          currentChange.content = trimmedChars
            .replace(/^===\s*|\s*===$/g, "")
            .trim();
        } else if (tagName === "complexity") {
          const complexityValue = parseInt(trimmedChars, 10);
          currentChange.complexity = isNaN(complexityValue)
            ? null
            : complexityValue;
        } else if (tagName === "search") {
          currentChange.search = trimmedChars
            .replace(/^===\s*|\s*===$/g, "")
            .trim();
        }
      }
      currentTag = null;
      accumulatedChars = "";
    };

    parser.parseErrorOccurred = (line, column, message) => {
      parseError = `XML Parse Error at ${line}:${column}: ${message}`;
      console.error(parseError);
      return;
    };

    const success = parser.parse();

    if (!success || parseError) {
      console.error("XML parsing failed.", parseError || "");
      return null;
    }

    console.log("XML parsing successful.");
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
  // ... (same Markdown generation logic as in the previous version) ...
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
  // (Keep the existing addCommentToMemo function content as it was correct)
  // ... (same logic using makeApiRequest) ...
  const endpoint =
    config.url.replace(/\/$/, "") + `/api/v1/memos/${memoId}/comments`;
  const headers = {
    "Content-Type": "application/json",
    Authorization: `Bearer ${config.token}`,
  };
  const body = { content: commentText };
  console.log(`Adding comment to memo ID: ${memoId}`);
  // Expects JSON response
  return await makeApiRequest(endpoint, "POST", headers, body, 30, "Memos");
}

// --- Main Execution ---

(async () => {
  console.log(
    "Starting Interactive Quick Capture (with AI Plan) to Memos script..."
  );
  let forceConfigPrompt = false;

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
      if (Keychain.contains(KEYCHAIN_URL_KEY))
        Keychain.remove(KEYCHAIN_URL_KEY);
      if (Keychain.contains(KEYCHAIN_TOKEN_KEY))
        Keychain.remove(KEYCHAIN_TOKEN_KEY);
      if (Keychain.contains(KEYCHAIN_OPENAI_KEY))
        Keychain.remove(KEYCHAIN_OPENAI_KEY);
      console.log("Configuration removed.");
      forceConfigPrompt = true; // Force the prompt after resetting
    } else {
      console.log("Configuration reset cancelled.");
      Script.complete();
      return;
    }
  }
  // --- End Configuration Reset Logic ---

  let config;
  let originalInputText; // Renamed from inputData
  let createdMemo;
  let memoId;
  let finalText;
  let planUsed = false;

  try {
    config = await getConfig(forceConfigPrompt);
    console.log(
      "Configuration obtained:",
      config
        ? `URL: ${!!config.url}, Token: ${!!config.token}, OpenAI Key: ${!!config.openaiApiKey}`
        : "Failed"
    );

    const hasValidOpenAIKey =
      typeof config.openaiApiKey === "string" &&
      config.openaiApiKey.trim().length > 0;
    console.log(`Has valid OpenAI Key for AI processing? ${hasValidOpenAIKey}`);

    // Get input text (no AI option involved here anymore)
    originalInputText = await getInputText();

    if (originalInputText === null) {
      // getInputText now returns string or null
      console.log("No input text provided or cancelled. Exiting.");
      Script.complete();
      return;
    }

    finalText = originalInputText; // Default to original text

    // --- AI Plan Generation Flow ---
    // Trigger AI ONLY if a valid key exists
    if (hasValidOpenAIKey) {
      console.log(
        "Valid OpenAI Key found. Proceeding with AI plan generation..."
      );
      let processingAlert = null;
      try {
        processingAlert = new Alert();
        processingAlert.title = "Generating AI Plan...";
        processingAlert.message = "Please wait.";
        processingAlert.present();

        const rawXml = await getAiPlanAsXml(
          config.openaiApiKey,
          originalInputText
        );

        if (processingAlert && typeof processingAlert.dismiss === "function") {
          try {
            processingAlert.dismiss();
          } catch (e) {
            console.warn("Could not dismiss processing alert:", e);
          }
        }
        processingAlert = null;

        const parsedPlan = parseAiXmlResponse(rawXml);

        if (!parsedPlan) {
          throw new Error(
            "Failed to parse the AI-generated XML plan. The response might not be valid XML."
          );
        }

        console.log(
          "AI plan parsed successfully. Asking for review via WebView."
        );
        const reviewHtml = generatePlanReviewHtml(parsedPlan);
        const reviewResult = await presentWebViewForm(reviewHtml, true); // Present fullscreen

        if (reviewResult && typeof reviewResult.confirmedPlan !== "undefined") {
          if (reviewResult.confirmedPlan === true) {
            finalText = formatPlanForMemo(parsedPlan);
            planUsed = true;
            console.log("User confirmed using AI generated plan via WebView.");
          } else {
            // finalText remains originalInputText
            console.log("User chose to revert to original text via WebView.");
          }
        } else {
          // finalText remains originalInputText
          console.log(
            "AI plan review cancelled or failed. Reverting to original text."
          );
        }
      } catch (aiError) {
        if (processingAlert && typeof processingAlert.dismiss === "function") {
          try {
            processingAlert.dismiss();
          } catch (e) {
            console.warn("Could not dismiss processing alert:", e);
          }
        }
        console.error(`AI Plan Generation/Processing Failed: ${aiError}`);

        const aiErrorAlert = new Alert();
        aiErrorAlert.title = "AI Plan Error";
        aiErrorAlert.message = `Failed to generate or process AI plan:\n${aiError.message}\n\nUse original text instead?`;
        aiErrorAlert.addAction("Use Original");
        aiErrorAlert.addCancelAction("Cancel Script");
        const errorChoice = await aiErrorAlert.presentAlert();

        if (errorChoice === -1) {
          console.log("Script cancelled due to AI plan processing error.");
          Script.complete();
          return;
        }
        // finalText remains originalInputText
        console.log("Proceeding with original text after AI error.");
      }
    } else {
      // Log reason for skipping AI plan generation
      console.log(
        "Skipping AI plan generation: No valid OpenAI API Key configured."
      );
      // finalText is already originalInputText
    }
    // --- End AI Plan Generation Flow ---

    // --- Memos Creation ---
    console.log("Proceeding to create Memos entry...");
    const memoTitle = `Quick Capture - ${new Date().toLocaleString()}`;
    createdMemo = await createMemo(config, memoTitle);

    // FIX: Handle alphanumeric ID
    const nameParts = createdMemo?.name?.split("/");
    memoId = nameParts ? nameParts[nameParts.length - 1] : null;

    // Check if memoId is a non-empty string after extraction
    if (!memoId || typeof memoId !== "string" || memoId.trim() === "") {
      console.error(
        "Failed to get valid memo ID string from creation response.",
        createdMemo
      );
      throw new Error(
        `Could not determine the new memo's ID string from name: ${createdMemo?.name}`
      );
    }
    console.log(`Memo created successfully with ID: ${memoId}`);

    await addCommentToMemo(config, memoId, finalText);
    console.log("Comment added successfully!");

    // --- Success Alert ---
    let showAlerts = !(
      typeof args.runsInWidget === "boolean" && args.runsInWidget
    );
    if (showAlerts) {
      const successAlert = new Alert();
      successAlert.title = "Success";
      successAlert.message = "Memo and comment added to Memos.";
      if (planUsed) {
        // Check if the plan was actually used
        successAlert.message += "\n(Used AI generated plan)";
      }
      await successAlert.presentAlert();
    } else {
      console.log("Running in widget context, skipping success alert.");
    }
  } catch (e) {
    console.error(`Script execution failed: ${e}`);
    // --- Error Alert ---
    let showAlerts = !(
      typeof args.runsInWidget === "boolean" && args.runsInWidget
    );
    if (showAlerts) {
      const errorAlert = new Alert();
      errorAlert.title = "Error";
      const errorMessage = e.message || "An unknown error occurred.";
      errorAlert.message = `Script failed: ${errorMessage}`;
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
        } else if (
          e.message.toLowerCase().includes("xml parse error") ||
          e.message.toLowerCase().includes("valid xml")
        ) {
          errorAlert.message += "\n\nAI response was not valid XML.";
        } else if (
          e.message.includes("Configuration incomplete") ||
          e.message.includes("Configuration cancelled")
        ) {
          errorAlert.message +=
            "\n\nPlease ensure Memos URL and Token are configured correctly.";
        } else if (e.message.includes("ID string from name")) {
          errorAlert.message +=
            "\n\nCould not parse Memo ID from API response.";
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
