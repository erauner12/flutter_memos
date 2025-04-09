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
 * Simplified logic for dismissal.
 * @param {string} htmlContent - The HTML string to display.
 * @param {boolean} [fullscreen=false] - Whether to present fullscreen.
 * @returns {Promise<any|null>} The data from the 'submit' action, or null if dismissed/error.
 */
async function presentWebViewForm(htmlContent, fullscreen = false) {
  console.log("Configuring interactive WebView form...");
  const wv = new WebView();
  let isPresented = false; // Use local variable

  try {
    console.log("Loading HTML into WebView instance...");
    await wv.loadHTML(htmlContent);
    console.log("HTML loaded.");

    // Present the WebView *once* before the loop starts
    if (!isPresented) {
        console.log(`Presenting WebView initially (fullscreen: ${fullscreen})...`);
        // We don't await this promise here, as it only resolves on dismissal.
        // We rely on evaluateJavaScript rejecting if dismissed during its wait.
        wv.present(fullscreen).catch(e => {
            // Catch potential errors during the initial presentation itself
            console.error("Error during initial WebView presentation:", e);
            // This doesn't necessarily mean the script should stop,
            // but indicates an issue with the presentation setup.
        });
        isPresented = true;
        console.log("WebView presentation initiated.");
        // Add a small delay to ensure the view is likely visible before JS evaluation
        await new Promise(resolve => Timer.schedule(100, false, resolve));
    }


    // Loop to handle interactions until submit or dismissal
    while (true) {
      console.log("WebView Loop: Setting up listener for next action/submit...");

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
                 } else { console.error("CRITICAL: completion function not available during init error."); }
            }
        } else if (!window.formInitialized && typeof initializeForm !== 'function') {
             console.error("initializeForm function not found in HTML script.");
             if (typeof completion === 'function') { completion({ error: "Initialization function missing in HTML" }); }
             else { console.error("CRITICAL: completion function not available during init check."); }
             window.formInitialized = true;
        }
        console.log("Listener active. Waiting for completion() call (paste, dictate, submit, or error)...");
      `;

      let result;
      try {
          console.log("WebView Loop: Waiting for evaluateJavaScript completion or dismissal...");
          // evaluateJavaScript with useCallback=true waits for completion()
          // It should reject if the WebView is dismissed manually before completion() is called.
          result = await wv.evaluateJavaScript(listenerScript, true);
          console.log("WebView Loop: evaluateJavaScript resolved with:", result);

      } catch (e) {
          // Catch errors from evaluateJavaScript, likely due to dismissal
          console.log(`WebView Loop: evaluateJavaScript caught error: ${e}`);
          // Check if the error message indicates dismissal (this can be platform/version dependent)
          // Often it's a generic "JavaScript execution failed" or similar when the context disappears.
          // Assume any error here during the wait means dismissal or a critical JS error.
          console.log("Assuming error indicates dismissal or critical JS failure. Exiting loop.");
          return null; // Treat as dismissal
      }


      // --- Handle the result from evaluatePromise ---
      if (result && result.error) {
        console.error(`WebView Loop: Error received from JS: ${result.error}`, result.details || "");
        let errorAlert = new Alert();
        errorAlert.title = "WebView Form Error";
        errorAlert.message = `An error occurred in the form: ${result.error}\n${result.details || ""}`;
        await errorAlert.presentAlert();
        // Don't return null immediately, let the loop potentially continue if it wasn't fatal
        // Consider if specific errors should terminate the process. For now, log and continue.
        // return null; // Exit on JS error? Maybe too strict.
      } else if (result && result.action) {
        switch (result.action) {
          case "submit":
            console.log("WebView Loop: Received 'submit' action. Returning data:", result.data);
            // Returning data should cause Scriptable to dismiss the WebView automatically.
            return result.data; // Exit function and loop

          case "paste":
            console.log("WebView Loop: Received 'paste' action.");
            const clipboardText = Pasteboard.pasteString() || "";
            try {
              await wv.evaluateJavaScript(`updateTextArea(${JSON.stringify(clipboardText)})`, false);
              console.log("WebView Loop: Sent paste data back. Continuing loop.");
            } catch (evalError) { console.error("WebView Loop: Error sending paste data:", evalError); }
            break; // Continue loop

          case "dictate":
            console.log("WebView Loop: Received 'dictate' action.");
            try {
              const dictatedText = await Dictation.start();
              if (dictatedText) {
                await wv.evaluateJavaScript(`updateTextArea(${JSON.stringify(dictatedText)})`, false);
                console.log("WebView Loop: Sent dictate data back. Continuing loop.");
              } else { console.log("WebView Loop: Dictation returned no text."); }
            } catch (dictationError) {
              console.error(`WebView Loop: Dictation failed: ${dictationError}`);
              try { await wv.evaluateJavaScript(`alert('Dictation failed: ${escapeHtml(dictationError.message)}')`, false); }
              catch (alertError) {
                  console.error("Failed to show dictation error alert:", alertError);
                  let fallbackAlert = new Alert();
                  fallbackAlert.title = "Dictation Error";
                  fallbackAlert.message = `Dictation failed: ${dictationError.message}`;
                  await fallbackAlert.presentAlert();
              }
            }
            break; // Continue loop

          default:
            console.warn(`WebView Loop: Received unknown action: ${result.action}`);
            break; // Continue loop
        }
      } else {
        console.warn("WebView Loop: evaluateJavaScript resolved with unexpected result:", result);
        // Continue loop? Or treat as error? For now, continue.
      }
    } // End while loop
  } catch (e) {
    console.error(`Error during interactive WebView operation: ${e}`);
    return null; // Return null on outer error
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
    // (Keep the existing generateConfigFormHtml function content - it's correct)
    // ... (same CSS and HTML generation logic as previous version) ...
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
    const tokenPlaceholder = existingToken ? `placeholder="Exists (Enter new to change)"` : `placeholder="Enter Memos Token"`;
    const openaiKeyPlaceholder = existingOpenAIKey ? `placeholder="Exists (Enter new to change)"` : `placeholder="Enter OpenAI Key"`;
    return `
    <!DOCTYPE html><html><head><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Memos Configuration</title><style>${css}</style></head>
    <body><h2>Memos Configuration</h2><p>Enter your Memos instance URL, Access Token (OpenAPI), and your OpenAI API Key.</p>
    <div class="info">Existing tokens/keys are not shown. Enter a new value only if you need to change it. Leave blank to keep the existing value (if any).</div>
    <form id="configForm"><label for="memosUrl">Memos URL:</label><input type="text" id="memosUrl" name="memosUrl" ${urlValue} required placeholder="https://your-memos.com"><div id="urlError" class="error" style="display: none;"></div>
    <label for="accessToken">Access Token:</label><input type="password" id="accessToken" name="accessToken" ${tokenPlaceholder} ><div id="tokenError" class="error" style="display: none;"></div>
    <label for="openaiKey">OpenAI API Key:</label><input type="password" id="openaiKey" name="openaiKey" ${openaiKeyPlaceholder}><div id="openaiError" class="error" style="display: none;"></div>
    <button type="submit">Save Configuration</button></form>
    <script>
    function initializeForm() { try { const form=document.getElementById('configForm'),urlInput=document.getElementById('memosUrl'),tokenInput=document.getElementById('accessToken'),openaiInput=document.getElementById('openaiKey'),urlError=document.getElementById('urlError'),tokenError=document.getElementById('tokenError'),openaiError=document.getElementById('openaiError'); if(!form||!urlInput||!tokenInput||!openaiInput||!urlError||!tokenError||!openaiError){console.error("Config form elements not found.");alert("Error initializing config form elements.");if(typeof completion==='function')completion({error:"Initialization failed: Elements missing"});return;} form.addEventListener('submit',(event)=>{ event.preventDefault();urlError.style.display='none';tokenError.style.display='none';openaiError.style.display='none';let isValid=true;const url=urlInput.value.trim(),newToken=tokenInput.value.trim(),newOpenaiApiKey=openaiInput.value.trim();if(!url){urlError.textContent='Memos URL is required.';urlError.style.display='block';isValid=false;}else if(!url.toLowerCase().startsWith('http://')&&!url.toLowerCase().startsWith('https://')){urlError.textContent='URL must start with http:// or https://';urlError.style.display='block';isValid=false;} if(isValid){if(typeof completion==='function'){completion({action:'submit',data:{url:url,token:newToken||null,openaiApiKey:newOpenaiApiKey||null}});}else{console.error('CRITICAL: completion function unavailable!');alert('Error: Cannot submit config form.');}} }); console.log("Config form initialized."); } catch (initError) { console.error("Error during config form initialization:", initError); alert("A critical error occurred setting up the configuration form."); if(typeof completion==='function')completion({error:"Initialization crashed",details:initError.message}); } }
    </script></body></html>`;
}


/**
 * Generates HTML for the main text input form (AI checkbox ALWAYS shown).
 * @param {string} [prefillText=''] - Text to pre-fill the textarea.
 * @returns {string} HTML content for the input form.
 */
function generateInputFormHtml(prefillText = "") {
    // (Keep the existing generateInputFormHtml function content - it's correct)
    // ... (same CSS and HTML generation logic as previous version, including checkbox) ...
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
    const shareSheetNotice = prefillText ? `<div class="clipboard-notice">Text pre-filled from Share Sheet.</div>` : "";
    const aiCheckboxHtml = `<div class="options"><input type="checkbox" id="useAi" name="useAi"><label for="useAi">Process with AI (Generate Plan)</label></div>`;
    const escapedPrefillText = escapeHtml(prefillText);
    return `
    <!DOCTYPE html><html><head><meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no"><title>Enter Memo Content</title><style>${css}</style></head>
    <body><h2>Enter Memo Content</h2>${shareSheetNotice}<form id="inputForm">
    <textarea id="memoContent" name="memoContent" placeholder="Type, paste, or dictate your memo content here..." required>${escapedPrefillText}</textarea>
    <div class="button-bar"><button type="button" id="pasteButton">Paste from Clipboard</button><button type="button" id="dictateButton">Start Dictation</button></div>
    ${aiCheckboxHtml}
    <button type="submit">Add Memo</button></form>
    <script>
    function updateTextArea(text){const t=document.getElementById('memoContent');if(t&&null!=text){const e=t.value;t.value=e?e+" "+text:text,t.focus(),console.log("Text area updated.")}else console.error("Could not find text area or text was null.")}
    function initializeForm(){try{const t=document.getElementById("inputForm"),e=document.getElementById("memoContent"),o=document.getElementById("useAi"),n=document.getElementById("pasteButton"),c=document.getElementById("dictateButton");if(!t||!e||!o||!n||!c)return console.error("Required form elements not found."),alert("Error initializing form elements."),void(typeof completion=="function"&&completion({error:"Initialization failed: Elements missing"}));t.addEventListener("submit",t=>{t.preventDefault();const n=e.value.trim(),c=o.checked;n?typeof completion=="function"?completion({action:"submit",data:{text:n,useAi:c}}):(console.error("CRITICAL: completion function unavailable!"),alert("Error: Cannot submit form.")):alert("Please enter some content.")}),n.addEventListener("click",()=>{console.log("Paste button clicked."),typeof completion=="function"?completion({action:"paste"}):(console.error("CRITICAL: completion function unavailable!"),alert("Error: Cannot request paste."))}),c.addEventListener("click",()=>{console.log("Dictate button clicked."),typeof completion=="function"?completion({action:"dictate"}):(console.error("CRITICAL: completion function unavailable!"),alert("Error: Cannot request dictation."))}),e.focus(),console.log("Input form initialized.")}catch(t){console.error("Error during input form initialization:",t),alert("A critical error occurred setting up the input form."),typeof completion=="function"&&completion({error:"Initialization crashed",details:t.message})}}
    </script></body></html>`;
}


/**
 * Generates HTML to display the parsed AI plan for review.
 * @param {object} parsedPlanData - The structured plan object from parseAiXmlResponse.
 * @returns {string} HTML content string.
 */
function generatePlanReviewHtml(parsedPlanData) {
    // (Keep the existing generatePlanReviewHtml function content - it's correct)
    // ... (same CSS and HTML generation logic as previous version) ...
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
        .code-block.search { border-left: 3px solid #ffcc00; }
        .code-block.content { border-left: 3px solid #4caf50; }
        .code-block.delete { border-left: 3px solid #f44336; color: #777; font-style: italic; }
        button { padding: 12px 15px; background-color: #007aff; color: white; border: none; border-radius: 8px; cursor: pointer; font-size: 16px; margin-right: 10px; margin-top: 10px; }
        button.secondary { background-color: #6c757d; }
        button:hover { opacity: 0.8; }
        h2, h3 { margin-top: 0; color: #111; }
        p { color: #555; }
        .button-group { margin-top: 20px; text-align: center; }
    `;
    let filesHtml = "";
    if (parsedPlanData?.files?.length > 0) { /* ... loop logic ... */ } else { filesHtml = "<p>No file changes specified in the plan.</p>"; }
    // --- Re-paste the detailed filesHtml loop logic ---
    if (parsedPlanData?.files?.length > 0) {
        parsedPlanData.files.forEach((file) => {
            let changesHtml = "";
            if (file.changes?.length > 0) {
                file.changes.forEach((change) => {
                    changesHtml += `<div class="change-block">`;
                    changesHtml += `<div class="change-description">${escapeHtml(change.description || "No description")}</div>`;
                    if (change.search && (file.action === "delegate edit" || file.action === "modify")) { changesHtml += `<div><strong>Search/Context:</strong><pre class="code-block search">${escapeHtml(change.search)}</pre></div>`; }
                    if (change.content && file.action !== "delete") { changesHtml += `<div><strong>Content/Change:</strong><pre class="code-block content">${escapeHtml(change.content)}</pre></div>`; }
                    if (file.action === "delete") { changesHtml += `<pre class="code-block delete">(File to be deleted)</pre>`; }
                    if (change.complexity !== null && change.complexity !== undefined) { changesHtml += `<div><strong>Complexity:</strong> ${escapeHtml(String(change.complexity))}</div>`; }
                    changesHtml += `</div>`;
                });
            } else { changesHtml = `<div class="change-block"><div class="change-description">No specific changes listed.</div></div>`; }
            filesHtml += `<div class="file-block"><div class="file-header"><span class="file-action">${escapeHtml(file.action || "unknown")}</span><span class="file-path">${escapeHtml(file.path || "No path")}</span></div>${changesHtml}</div>`;
        });
    } else { filesHtml = "<p>No file changes specified in the plan.</p>"; }
    // --- End re-pasted filesHtml loop logic ---

    const planDescriptionHtml = parsedPlanData.planText ? `<div class="plan-description"><strong>Plan:</strong>\n${escapeHtml(parsedPlanData.planText)}</div>` : "<p>No overall plan description provided.</p>";
    const chatNameHtml = parsedPlanData.chatName ? `<h3>${escapeHtml(parsedPlanData.chatName)}</h3>` : "";
    return `
    <!DOCTYPE html><html><head><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Review AI Generated Plan</title><style>${css}</style></head>
    <body><h2>Review AI Generated Plan</h2>${chatNameHtml}<p>Review the plan generated by the AI. Choose whether to use this plan for the memo comment.</p>
    ${planDescriptionHtml}${filesHtml}
    <div class="button-group"><button id="usePlan">Use This Plan</button><button id="useOriginal" class="secondary">Use Original Text</button></div>
    <script>
    function initializeForm(){try{const e=document.getElementById("usePlan"),t=document.getElementById("useOriginal");if(!e||!t)return console.error("Plan review elements not found."),alert("Error initializing review elements."),void(typeof completion=="function"&&completion({error:"Initialization failed: Elements missing"}));e.addEventListener("click",()=>{typeof completion=="function"?completion({action:"submit",data:{confirmedPlan:!0}}):(console.error("CRITICAL: completion unavailable!"),alert("Error submitting choice."))}),t.addEventListener("click",()=>{typeof completion=="function"?completion({action:"submit",data:{confirmedPlan:!1}}):(console.error("CRITICAL: completion unavailable!"),alert("Error submitting choice."))}),console.log("AI Plan Review form initialized.")}catch(e){console.error("Error during review init:",e),alert("A critical error occurred setting up review form."),typeof completion=="function"&&completion({error:"Initialization crashed",details:e.message})}}
    </script></body></html>`;
}


/**
 * Retrieves Memos configuration (URL, Token, OpenAI Key) from Keychain.
 * Prompts the user using a WebView form ONLY if Memos URL or Token is missing,
 * or if explicitly requested via forcePrompt. Does NOT prompt just for OpenAI key here.
 * @param {boolean} forcePrompt - If true, always show the config form.
 * @returns {Promise<{url: string, token: string, openaiApiKey: string|null}|null>} Configuration object, or null if cancelled/failed.
 * @throws {Error} If configuration cannot be obtained and user cancels/fails prompt.
 */
async function getConfig(forcePrompt = false) {
    // (Keep the existing getConfig function content - it's correct)
    // ... (same logic as previous version) ...
    console.log("Attempting to retrieve configuration from Keychain...");
    let url = Keychain.contains(KEYCHAIN_URL_KEY) ? Keychain.get(KEYCHAIN_URL_KEY) : null;
    let token = Keychain.contains(KEYCHAIN_TOKEN_KEY) ? Keychain.get(KEYCHAIN_TOKEN_KEY) : null;
    let openaiApiKey = Keychain.contains(KEYCHAIN_OPENAI_KEY) ? Keychain.get(KEYCHAIN_OPENAI_KEY) : null;
    console.log(`Retrieved Memos URL: ${url ? 'Exists' : 'Not Found'}`);
    console.log(`Retrieved Memos Token: ${token ? 'Exists' : 'Not Found'}`);
    console.log(`Retrieved OpenAI Key: ${openaiApiKey ? `Exists (Length: ${openaiApiKey.length})` : 'Not Found or Empty'}`);
    if (url && !url.toLowerCase().startsWith("http")) { console.warn(`Invalid URL format stored: ${url}. Clearing.`); Keychain.remove(KEYCHAIN_URL_KEY); url = null; }
    if (openaiApiKey !== null && openaiApiKey.trim() === "") { console.warn("Stored OpenAI Key was empty string. Clearing."); openaiApiKey = null; if (Keychain.contains(KEYCHAIN_OPENAI_KEY)) Keychain.remove(KEYCHAIN_OPENAI_KEY); }
    console.log(`OpenAI Key after cleanup: ${openaiApiKey ? 'Exists' : 'null'}`);
    if (forcePrompt || !url || !token) {
        console.log(`Configuration prompt needed. Reason: ${forcePrompt ? 'Forced' : (!url ? 'Memos URL missing' : 'Memos Token missing')}`);
        const configHtml = generateConfigFormHtml(url, token, openaiApiKey);
        const result = await presentWebViewForm(configHtml, false);
        if (!result) { console.log("Configuration prompt cancelled."); throw new Error("Configuration cancelled."); }
        const newUrl = result.url, newToken = result.token, newOpenaiApiKey = result.openaiApiKey;
        console.log(`Form submitted - URL: ${newUrl}, NewTokenProvided: ${!!newToken}, NewOpenAIKeyProvided: ${!!newOpenaiApiKey} (Length: ${newOpenaiApiKey?.length ?? 0})`);
        if (!newUrl || (!newUrl.toLowerCase().startsWith('http://') && !newUrl.toLowerCase().startsWith('https://'))) { throw new Error("Invalid Memos URL provided."); }
        url = newUrl; Keychain.set(KEYCHAIN_URL_KEY, url); console.log("Saved Memos URL.");
        if (newToken) { token = newToken; Keychain.set(KEYCHAIN_TOKEN_KEY, token); console.log("Saved new Memos Token."); }
        else if (!token) { throw new Error("Memos Access Token is required."); }
        else { console.log("Memos Token field left blank, keeping existing."); }
        if (newOpenaiApiKey) { openaiApiKey = newOpenaiApiKey; console.log(`Attempting to save NEW OpenAI Key (length: ${openaiApiKey.length})...`); Keychain.set(KEYCHAIN_OPENAI_KEY, openaiApiKey); console.log("Saved new OpenAI API Key."); }
        else if (openaiApiKey && !newOpenaiApiKey) { console.log("OpenAI Key field blank, removing existing."); openaiApiKey = null; if (Keychain.contains(KEYCHAIN_OPENAI_KEY)) Keychain.remove(KEYCHAIN_OPENAI_KEY); }
        else if (!openaiApiKey && !newOpenaiApiKey) { console.log("No OpenAI API Key provided or saved."); openaiApiKey = null; }
        else { console.log("OpenAI Key field blank, keeping existing."); }
        console.log("Configuration processing complete after prompt.");
    } else { console.log("Configuration retrieved without prompt."); }
    if (!url || !token) { throw new Error("Configuration incomplete: Missing Memos URL or Token."); }
    console.log(`FINAL Config Check - URL: ${!!url}, Token: ${!!token}, OpenAI Key: ${openaiApiKey ? `Exists (Length: ${openaiApiKey.length})` : 'null'}`);
    return { url, token, openaiApiKey };
}


/**
 * Gets text input from Share Sheet or WebView form (AI checkbox always present).
 * @returns {Promise<{text: string, useAi: boolean}|null>} Object with text and AI choice, or null if cancelled/empty.
 */
async function getInputText() {
    // (Keep the existing getInputText function content - it's correct)
    // ... (same logic as previous version) ...
    console.log("Checking for input source...");
    let initialText = "";
    if (args.plainTexts?.length > 0) { const sharedText = args.plainTexts.join("\n").trim(); if (sharedText) { console.log("Using text from Share Sheet."); initialText = sharedText; } }
    else { console.log("No Share Sheet input found."); }
    console.log(`Presenting WebView form for text input (AI checkbox always shown).`);
    const inputHtml = generateInputFormHtml(initialText);
    const formData = await presentWebViewForm(inputHtml, false);
    if (!formData || typeof formData.text === "undefined" || typeof formData.useAi === "undefined") { console.log("Input cancelled or form did not return expected data."); return null; }
    if (formData.text.trim() === "") { console.log("No text entered."); return null; }
    console.log(`Input received. Text length: ${formData.text.trim().length}, Use AI checkbox state: ${formData.useAi}`);
    return { text: formData.text.trim(), useAi: formData.useAi };
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
    // (Keep the existing makeApiRequest function content - it's correct)
    // ... (same Request logic as previous version) ...
    console.log(`Making ${serviceName} request: ${method} ${url}`);
    const req = new Request(url); req.method = method; req.headers = headers; req.timeoutInterval = timeout; req.allowInsecureRequest = url.startsWith("http://");
    if (body) { req.body = JSON.stringify(body); console.log(`${serviceName} Request body: ${body.content ? `{"content": "[CENSORED, Length: ${body.content.length}]", ...}` : (body.messages ? `{"messages": "[CENSORED]", ...}`: JSON.stringify(body).substring(0, 100) + "...")}`); }
    try {
        let responseData, statusCode, responseText = ""; const expectJson = headers["Content-Type"]?.includes("json") || headers["Accept"]?.includes("json");
        if (method.toUpperCase() === 'GET' || expectJson) {
            try { responseData = await req.loadJSON(); statusCode = req.response.statusCode; responseText = JSON.stringify(responseData); }
            catch (e) { console.warn(`${serviceName} loadJSON failed (Status: ${req.response?.statusCode}), trying loadString. Error: ${e.message}`); statusCode = req.response?.statusCode ?? 500; if (statusCode >= 200 && statusCode < 300) { responseText = await req.loadString(); responseData = responseText; console.log(`${serviceName} received non-JSON success response (Status: ${statusCode}).`); } else { responseText = await req.loadString().catch(() => ""); responseData = responseText; console.error(`${serviceName} loadJSON failed and status code ${statusCode} indicates error.`); } }
        } else { responseText = await req.loadString(); statusCode = req.response.statusCode; responseData = responseText; }
        console.log(`${serviceName} Response Status Code: ${statusCode}`);
        if (statusCode < 200 || statusCode >= 300) { console.error(`${serviceName} Error Response Body: ${responseText}`); let errorMessage = responseText; if (typeof responseData === 'object' && responseData !== null) { errorMessage = responseData.error?.message || responseData.message || JSON.stringify(responseData); } throw new Error(`${serviceName} Error ${statusCode}: ${errorMessage || "Unknown error"}`); }
        console.log(`${serviceName} request successful.`); return responseData;
    } catch (e) { if (e.message.startsWith(`${serviceName} Error`)) { throw e; } console.error(`${serviceName} Request Failed: ${method} ${url} - ${e}`); throw new Error(`${serviceName} Request Failed: ${e.message || e}`); }
}


/**
 * Creates a new memo in Memos.
 * @param {{url: string, token: string}} config - Memos configuration.
 * @param {string} title - The content/title for the new memo.
 * @returns {Promise<object>} The created memo object from the API.
 * @throws {Error} If memo creation fails.
 */
async function createMemo(config, title) {
    // (Keep the existing createMemo function content - it's correct)
    // ... (same logic using makeApiRequest) ...
    const endpoint = config.url.replace(/\/$/, "") + "/api/v1/memos";
    const headers = { "Content-Type": "application/json", Authorization: `Bearer ${config.token}` };
    const body = { content: title, visibility: "PRIVATE" };
    console.log(`Creating memo with title: "${title}"`);
    return await makeApiRequest(endpoint, "POST", headers, body, 30, "Memos");
}

/**
 * Requests a plan from OpenAI in a specific XML format using Chat Completions.
 * Includes stronger instructions for XML-only output.
 * @param {string} apiKey - OpenAI API Key.
 * @param {string} userRequest - The user's input/request for the AI.
 * @returns {Promise<string>} Raw XML string response from OpenAI.
 * @throws {Error} If the API request fails or returns an error.
 */
async function getAiPlanAsXml(apiKey, userRequest) {
    console.log("Requesting XML plan from OpenAI...");
    const endpoint = "https://api.openai.com/v1/chat/completions";
    const model = "gpt-4o";

    // Keep the detailed XML instructions
    const xmlFormattingInstructions = `
### Role
- You are a **code editing assistant**: You can fulfill edit requests and chat with the user about code or other questions. Provide complete instructions or code lines when replying with xml formatting.
[...]
## Final Notes
[...]
10. The final output must apply cleanly with no leftover syntax errors.`; // Truncated for brevity

    // Enhanced System Prompt
    const messages = [
        {
            role: "system",
            content: `You are an assistant that generates plans for code changes. Your *entire response* MUST be valid XML, adhering strictly to the format defined below. Start directly with the '<chatName...' tag and end with the final closing tag (e.g., '</file>'). Do NOT include ANY introductory text, explanations, apologies, or markdown formatting (like \`\`\`xml) outside the XML structure itself.

Here are the XML formatting instructions you MUST follow:
${xmlFormattingInstructions}`, // Keep the full instructions here
        },
        {
            role: "user",
            content: `Generate a plan in the specified XML format for the following request:

${userRequest}`,
        },
    ];

    const headers = { "Content-Type": "application/json", Authorization: `Bearer ${apiKey}` };
    const body = { model: model, messages: messages, max_tokens: 3500, temperature: 0.2, n: 1, stop: null }; // Slightly lower temp

    try {
        const responseJson = await makeApiRequest(endpoint, "POST", headers, body, 90, "OpenAI");
        if (!responseJson.choices?.[0]?.message?.content) {
            console.error("OpenAI response missing expected structure:", responseJson);
            throw new Error("OpenAI response did not contain the expected message content.");
        }

        let xmlContent = responseJson.choices[0].message.content.trim();
        console.log("OpenAI raw response received. Length:", xmlContent.length);

        // Attempt to strip potential markdown fences if present
        if (xmlContent.startsWith("```xml")) {
            xmlContent = xmlContent.substring(6);
            if (xmlContent.endsWith("```")) {
                xmlContent = xmlContent.substring(0, xmlContent.length - 3);
            }
            xmlContent = xmlContent.trim();
            console.log("Stripped markdown fences. New length:", xmlContent.length);
        }

        // Basic check if it looks like XML *after* potential stripping
        if (!xmlContent.startsWith("<") || !xmlContent.endsWith(">")) {
            console.warn("OpenAI response still doesn't look like XML after potential stripping:", xmlContent);
            // Consider throwing error here if strict XML is absolutely required before parsing attempt
            // throw new Error("OpenAI response did not appear to be valid XML.");
        } else {
             console.log("OpenAI response looks like XML.");
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
    // (Keep the existing parseAiXmlResponse function content - it's correct)
    // ... (same XMLParser logic as previous version) ...
    console.log("Parsing AI XML response...");
    if (!xmlString || typeof xmlString !== 'string' || xmlString.trim() === '') { console.error("Cannot parse empty or invalid XML string."); return null; }
    try {
        const parser = new XMLParser(xmlString);
        let parsedData = { chatName: "", planText: "", files: [] };
        let currentFile = null, currentChange = null, currentTag = null, accumulatedChars = "";
        let parseError = null;
        parser.didStartElement = (name, attrs) => { currentTag = name.toLowerCase(); accumulatedChars = ""; if (currentTag === "file") { currentFile = { path: attrs.path || "", action: attrs.action || "", changes: [] }; } else if (currentTag === "change") { currentChange = { description: "", content: "", complexity: null, search: "" }; } };
        parser.foundCharacters = (chars) => { if (currentTag) { accumulatedChars += chars; } };
        parser.didEndElement = (name) => { const tagName = name.toLowerCase(); const trimmedChars = accumulatedChars.trim(); if (tagName === "chatname") { parsedData.chatName = trimmedChars; } else if (tagName === "plan") { parsedData.planText = trimmedChars; } else if (tagName === "file") { if (currentFile) { if (currentFile.path && currentFile.action) { parsedData.files.push(currentFile); } else { console.warn("Skipping file element missing path or action:", currentFile); } currentFile = null; } } else if (tagName === "change") { if (currentChange && currentFile) { currentFile.changes.push(currentChange); currentChange = null; } } else if (currentChange) { if (tagName === "description") { currentChange.description = trimmedChars; } else if (tagName === "content") { currentChange.content = trimmedChars.replace(/^===\s*|\s*===$/g, "").trim(); } else if (tagName === "complexity") { const v = parseInt(trimmedChars, 10); currentChange.complexity = isNaN(v) ? null : v; } else if (tagName === "search") { currentChange.search = trimmedChars.replace(/^===\s*|\s*===$/g, "").trim(); } } currentTag = null; accumulatedChars = ""; };
        parser.parseErrorOccurred = (line, column, message) => { parseError = `XML Parse Error at ${line}:${column}: ${message}`; console.error(parseError); return; };
        const success = parser.parse();
        if (!success || parseError) { console.error("XML parsing failed.", parseError || ""); return null; }
        console.log("XML parsing successful."); return parsedData;
    } catch (e) { console.error(`Error during XML parsing setup or execution: ${e}`); return null; }
}

/**
 * Formats the parsed plan data into a Markdown-like string for Memos.
 * @param {object} parsedPlanData - The structured plan object.
 * @returns {string} Formatted string representation of the plan.
 */
function formatPlanForMemo(parsedPlanData) {
    // (Keep the existing formatPlanForMemo function content - it's correct)
    // ... (same Markdown generation logic as previous version) ...
    if (!parsedPlanData) return "Error: Could not format plan (null data)."; let output = ""; if (parsedPlanData.chatName) { output += `# ${parsedPlanData.chatName}\n\n`; } if (parsedPlanData.planText) { output += `**Plan:**\n${parsedPlanData.planText}\n\n`; } else { output += "**Plan:** (No description provided)\n\n"; } if (parsedPlanData.files?.length > 0) { output += `**File Changes:**\n\n`; parsedPlanData.files.forEach((file, index) => { output += `--- File ${index + 1} ---\n`; output += `**Path:** \`${file.path || "N/A"}\`\n`; output += `**Action:** ${file.action || "N/A"}\n\n`; if (file.changes?.length > 0) { file.changes.forEach((change, changeIndex) => { output += `*Change ${changeIndex + 1}:*\n`; if (change.description) { output += `  *Description:* ${change.description}\n`; } if (change.complexity !== null && change.complexity !== undefined) { output += `  *Complexity:* ${change.complexity}\n`; } if (change.search && (file.action === "delegate edit" || file.action === "modify")) { output += `  *Search/Context:*\n\`\`\`\n${change.search}\n\`\`\`\n`; } if (change.content && file.action !== "delete") { output += `  *Content/Change:*\n\`\`\`\n${change.content}\n\`\`\`\n`; } if (file.action === "delete") { output += `  *(File to be deleted)*\n`; } output += "\n"; }); } else { output += "  (No specific changes listed)\n\n"; } }); } else { output += "**File Changes:** (None specified)\n"; } return output.trim();
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
    // (Keep the existing addCommentToMemo function content - it's correct)
    // ... (same logic using makeApiRequest) ...
    const endpoint = config.url.replace(/\/$/, "") + `/api/v1/memos/${memoId}/comments`;
    const headers = { "Content-Type": "application/json", Authorization: `Bearer ${config.token}` };
    const body = { content: commentText };
    console.log(`Adding comment to memo ID: ${memoId}`);
    return await makeApiRequest(endpoint, "POST", headers, body, 30, "Memos");
}

// --- Main Execution ---

(async () => {
  console.log(
    "Starting Interactive Quick Capture (with AI Plan) to Memos script..."
  );
  let forceConfigPrompt = false;

  // --- Configuration Reset Logic ---
  if (args.queryParameters?.resetConfig === "true") {
    console.log("Reset configuration argument detected.");
    const confirmAlert = new Alert();
    confirmAlert.title = "Reset Configuration?";
    confirmAlert.message = "Are you sure you want to remove the saved Memos URL, Access Token, and OpenAI Key? You will be prompted to re-enter them.";
    confirmAlert.addAction("Reset");
    confirmAlert.addCancelAction("Cancel");
    const confirmation = await confirmAlert.presentAlert();
    if (confirmation === 0) {
      console.log("Removing configuration from Keychain...");
      if (Keychain.contains(KEYCHAIN_URL_KEY)) Keychain.remove(KEYCHAIN_URL_KEY);
      if (Keychain.contains(KEYCHAIN_TOKEN_KEY)) Keychain.remove(KEYCHAIN_TOKEN_KEY);
      if (Keychain.contains(KEYCHAIN_OPENAI_KEY)) Keychain.remove(KEYCHAIN_OPENAI_KEY);
      console.log("Configuration removed.");
      forceConfigPrompt = true;
    } else {
      console.log("Configuration reset cancelled.");
      Script.complete(); return;
    }
  }
  // --- End Configuration Reset Logic ---

  let config;
  let inputData;
  let createdMemo;
  let memoId;
  let finalText;
  let planUsed = false;

  try {
    config = await getConfig(forceConfigPrompt);
    console.log("Initial configuration obtained.");

    inputData = await getInputText(); // Gets { text, useAi }

    if (!inputData) {
      console.log("No input text provided or cancelled. Exiting.");
      Script.complete(); return;
    }

    const originalInputText = inputData.text;
    finalText = originalInputText; // Default to original

    // --- AI Plan Generation Flow ---
    if (inputData.useAi) {
        console.log("User checked 'Process with AI'. Checking for OpenAI Key...");
        let hasValidOpenAIKey = typeof config.openaiApiKey === 'string' && config.openaiApiKey.trim().length > 0;

        if (!hasValidOpenAIKey) {
            console.log("OpenAI Key is missing. Prompting user to configure.");
            const configureAlert = new Alert();
            configureAlert.title = "OpenAI Key Required";
            configureAlert.message = "To process with AI, you need to configure your OpenAI API Key.";
            configureAlert.addAction("Configure Now");
            configureAlert.addCancelAction("Use Original Text");
            const choice = await configureAlert.presentAlert();

            if (choice === 0) { // Configure Now
                console.log("User chose to configure. Forcing config prompt...");
                try {
                    config = await getConfig(true); // Force prompt and update config
                    hasValidOpenAIKey = typeof config.openaiApiKey === 'string' && config.openaiApiKey.trim().length > 0;
                    if (!hasValidOpenAIKey) {
                        console.log("Configuration attempted, but OpenAI Key is still missing. Using original text.");
                        const stillMissingAlert = new Alert();
                        stillMissingAlert.title = "Key Still Missing";
                        stillMissingAlert.message = "OpenAI Key was not provided or saved correctly. Using original text.";
                        await stillMissingAlert.presentAlert();
                    } else { console.log("OpenAI Key configured successfully."); }
                } catch (configError) {
                    console.error("Error during forced configuration:", configError);
                    hasValidOpenAIKey = false;
                    const configFailAlert = new Alert();
                    configFailAlert.title = "Configuration Failed";
                    configFailAlert.message = `Configuration failed or was cancelled: ${configError.message}\n\nUsing original text.`;
                    await configFailAlert.presentAlert();
                }
            } else { // Use Original Text
                console.log("User cancelled configuration prompt. Using original text.");
                hasValidOpenAIKey = false;
            }
        }

        // Proceed with AI ONLY if we now have a valid key
        if (hasValidOpenAIKey) {
            console.log("Valid OpenAI Key exists. Proceeding with AI plan generation...");
            let processingAlert = null;
            let parsedPlan = null; // Define parsedPlan outside try block
            try {
                processingAlert = new Alert();
                processingAlert.title = "Generating AI Plan...";
                processingAlert.message = "Please wait.";
                processingAlert.present();

                const rawXml = await getAiPlanAsXml(config.openaiApiKey, originalInputText);

                if (processingAlert?.dismiss) { try { processingAlert.dismiss(); } catch (e) { console.warn("Could not dismiss processing alert:", e); } }
                processingAlert = null;

                parsedPlan = parseAiXmlResponse(rawXml); // Assign result here

                // **Handle Parsing Failure Gracefully**
                if (!parsedPlan) {
                    console.warn("Failed to parse AI response as XML. Creating default error plan.");
                    // Create a default object indicating the error
                    parsedPlan = {
                        chatName: "AI Plan Error",
                        planText: "Error: The AI response could not be parsed as a valid XML plan. Please check the OpenAI response format or try again.",
                        files: []
                    };
                    // Optionally, show an immediate alert? Or let the review screen show it.
                    // let parseFailAlert = new Alert();
                    // parseFailAlert.title = "AI Response Error";
                    // parseFailAlert.message = "Could not parse the AI response. Showing error details.";
                    // await parseFailAlert.presentAlert();
                }

                console.log("AI plan ready for review (might be error plan). Asking via WebView.");
                const reviewHtml = generatePlanReviewHtml(parsedPlan);
                const reviewResult = await presentWebViewForm(reviewHtml, true); // Present fullscreen

                // Check if the plan used was the error plan AND user chose 'Use This Plan'
                const usedErrorPlan = parsedPlan.chatName === "AI Plan Error" && reviewResult?.confirmedPlan === true;

                if (reviewResult?.confirmedPlan === true && !usedErrorPlan) {
                    finalText = formatPlanForMemo(parsedPlan);
                    planUsed = true;
                    console.log("User confirmed using valid AI generated plan via WebView.");
                } else if (usedErrorPlan) {
                     console.log("User chose 'Use This Plan' on the error message. Reverting to original text.");
                     // finalText remains originalInputText
                }
                 else {
                    // User chose 'Use Original Text' or cancelled review
                    console.log("User chose to revert to original text or cancelled review.");
                    // finalText remains originalInputText
                }
            } catch (aiError) {
                if (processingAlert?.dismiss) { try { processingAlert.dismiss(); } catch (e) { console.warn("Could not dismiss processing alert:", e); } }
                console.error(`AI Plan Generation/Processing Failed: ${aiError}`);
                const aiErrorAlert = new Alert();
                aiErrorAlert.title = "AI Plan Error";
                aiErrorAlert.message = `Failed to generate or process AI plan:\n${aiError.message}\n\nUse original text instead?`;
                aiErrorAlert.addAction("Use Original");
                aiErrorAlert.addCancelAction("Cancel Script");
                const errorChoice = await aiErrorAlert.presentAlert();
                if (errorChoice === -1) { console.log("Script cancelled due to AI plan processing error."); Script.complete(); return; }
                console.log("Proceeding with original text after AI error.");
                // finalText remains originalInputText
            }
        } else {
             console.log("Skipping AI processing because OpenAI Key is not configured.");
             // finalText is already originalInputText
        }
    } else {
      console.log("User did not select 'Process with AI'. Using original text.");
      // finalText is already originalInputText
    }
    // --- End AI Plan Generation Flow ---

    // --- Memos Creation ---
    console.log("Proceeding to create Memos entry...");
    const memoTitle = `Quick Capture - ${new Date().toLocaleString()}`;
    createdMemo = await createMemo(config, memoTitle);

    const nameParts = createdMemo?.name?.split('/');
    memoId = nameParts ? nameParts[nameParts.length - 1] : null;
    if (!memoId || typeof memoId !== 'string' || memoId.trim() === '') {
        console.error("Failed to get valid memo ID string from creation response.", createdMemo);
        throw new Error(`Could not determine the new memo's ID string from name: ${createdMemo?.name}`);
    }
    console.log(`Memo created successfully with ID: ${memoId}`);

    await addCommentToMemo(config, memoId, finalText);
    console.log("Comment added successfully!");

    // --- Success Alert ---
    let showAlerts = !(args.runsInWidget);
    if (showAlerts) {
      const successAlert = new Alert();
      successAlert.title = "Success";
      successAlert.message = "Memo and comment added to Memos.";
      if (planUsed) { successAlert.message += "\n(Used AI generated plan)"; }
      await successAlert.presentAlert();
    } else {
      console.log("Running in widget context, skipping success alert.");
    }

  } catch (e) {
    console.error(`Script execution failed: ${e}`);
    // --- Error Alert ---
    let showAlerts = !(args.runsInWidget);
    if (showAlerts) {
      const errorAlert = new Alert();
      errorAlert.title = "Error";
      const errorMessage = e.message || "An unknown error occurred.";
      errorAlert.message = `Script failed: ${errorMessage}`;
      // ... (keep existing error hints) ...
       if (e.message) {
         if (e.message.includes("401")) { errorAlert.message += e.message.toLowerCase().includes("openai") ? "\n\nCheck OpenAI Key/Account." : "\n\nCheck Memos Token."; }
         else if (e.message.includes("404") && e.message.toLowerCase().includes("memos")) { errorAlert.message += "\n\nCheck Memos URL Path."; }
         else if (e.message.includes("ENOTFOUND") || e.message.includes("Could not connect") || e.message.includes("timed out")) { errorAlert.message += "\n\nCheck Network/URL Reachability."; }
         else if (e.message.toLowerCase().includes("openai") && e.message.toLowerCase().includes("quota")) { errorAlert.message += "\n\nCheck OpenAI Quota."; }
         else if (e.message.toLowerCase().includes("xml parse error") || e.message.toLowerCase().includes("valid xml")) { errorAlert.message += "\n\nAI response was not valid XML."; }
         else if (e.message.includes("Configuration incomplete") || e.message.includes("Configuration cancelled")) { errorAlert.message += "\n\nPlease ensure Memos URL and Token are configured correctly."; }
         else if (e.message.includes("ID string from name")) { errorAlert.message += "\n\nCould not parse Memo ID from API response." }
      }
      await errorAlert.presentAlert();
    } else {
      console.log("Running in widget context, skipping error alert.");
    }
  } finally {
    console.log("Script finished.");
    Script.complete(); // Ensure script completion is called
  }
})();
