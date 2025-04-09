// Variables used by Scriptable.
// These must be at the very top of the file. Do not edit.
// icon-color: blue; icon-glyph: tasks;

// Configuration Keys
const KEYCHAIN_URL_KEY = "memos_instance_url";
const KEYCHAIN_TOKEN_KEY = "memos_access_token";
const KEYCHAIN_OPENAI_KEY = "openai_api_key";

// --- Common AI Task Options ---
const COMMON_AI_TASKS = [
    { value: 'fix', label: 'Fix Grammar & Spelling' },
    { value: 'summarize', label: 'Summarize' },
    { value: 'list', label: 'Make Bullet List' },
    { value: 'formal', label: 'Make More Formal' },
    { value: 'casual', label: 'Make More Casual' },
];

// --- Helper Functions ---

/** Basic HTML escaping function */
function escapeHtml(unsafe) { /* ... (keep existing) ... */
    if (typeof unsafe !== "string") return "";
    return unsafe
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#039;");
}

/** Presents an HTML form in a WebView */
async function presentWebViewForm(htmlContent, fullscreen = false) { /* ... (keep existing - stable) ... */
    console.log("Configuring interactive WebView form..."); const wv = new WebView(); let isPresented = false;
    try {
        console.log("Loading HTML..."); await wv.loadHTML(htmlContent); console.log("HTML loaded.");
        if (!isPresented) { console.log(`Presenting WebView (fullscreen: ${fullscreen})...`); wv.present(fullscreen).catch(e => { console.error("Error during initial presentation:", e); }); isPresented = true; console.log("WebView presentation initiated."); await new Promise(resolve => Timer.schedule(100, false, resolve)); }
        while (true) {
            console.log("WebView Loop: Setting up listener..."); const listenerScript = ` if (typeof initializeForm === 'function' && !window.formInitialized) { console.log("Calling initializeForm()..."); try { initializeForm(); window.formInitialized = true; } catch (initErr) { console.error("Error executing initializeForm():", initErr); if (typeof completion === 'function') { completion({ error: "Form init failed", details: initErr.message }); } else { console.error("CRITICAL: completion unavailable."); } } } else if (!window.formInitialized && typeof initializeForm !== 'function') { console.error("initializeForm not found."); if (typeof completion === 'function') { completion({ error: "Init function missing" }); } else { console.error("CRITICAL: completion unavailable."); } window.formInitialized = true; } console.log("Listener active..."); `;
            let result;
            try { console.log("WebView Loop: Waiting for evaluateJavaScript..."); result = await wv.evaluateJavaScript(listenerScript, true); console.log("WebView Loop: evaluateJavaScript resolved:", result); }
            catch (e) { console.log(`WebView Loop: evaluateJavaScript caught error: ${e}`); console.log("Assuming dismissal or critical JS failure."); return null; }
            if (result?.error) { console.error(`WebView Loop: Error from JS: ${result.error}`, result.details || ""); /* Optionally alert */ }
            else if (result?.action) {
                switch (result.action) {
                    case "submit": console.log("WebView Loop: Received 'submit'. Returning data:", result.data); return result.data;
                    case "paste": console.log("WebView Loop: Received 'paste'."); const clipboardText = Pasteboard.pasteString() || ""; const pasteTargetId = await wv.evaluateJavaScript('window.activeTextAreaId || "memoContent"', false); console.log(`Pasting to target: ${pasteTargetId}`); try { await wv.evaluateJavaScript(`updateSpecificTextArea(${JSON.stringify(pasteTargetId)}, ${JSON.stringify(clipboardText)})`, false); console.log("Sent paste data."); } catch (evalError) { console.error("Error sending paste data:", evalError); } break;
                    case "dictate": console.log("WebView Loop: Received 'dictate'."); let dictateTargetId = 'memoContent'; try { dictateTargetId = await wv.evaluateJavaScript('window.activeTextAreaId || "memoContent"', false); console.log(`Dictation target element ID: ${dictateTargetId}`); const dictatedText = await Dictation.start(); if (dictatedText) { await wv.evaluateJavaScript(`updateSpecificTextArea(${JSON.stringify(dictateTargetId)}, ${JSON.stringify(dictatedText)})`, false); console.log("Sent dictate data to target."); } else { console.log("Dictation returned no text."); } } catch (dictationError) { console.error(`Dictation or targeting failed: ${dictationError}`); try { await wv.evaluateJavaScript(`alert('Dictation failed: ${escapeHtml(dictationError.message)}')`, false); } catch (alertError) { console.error("Failed to show dictation error alert:", alertError); let fallbackAlert = new Alert(); fallbackAlert.title = "Dictation Error"; fallbackAlert.message = `Dictation failed: ${dictationError.message}`; await fallbackAlert.presentAlert(); } } break;
                    default: console.warn(`WebView Loop: Unknown action: ${result.action}`); break;
                }
            } else { console.warn("WebView Loop: Unexpected result:", result); }
        }
    } catch (e) { console.error(`Error during interactive WebView operation: ${e}`); return null; }
}

/** Generates HTML for Memos configuration */
function generateConfigFormHtml(existingUrl, existingToken, existingOpenAIKey) { /* ... (keep existing - stable) ... */
    const css = ` body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; padding: 15px; background-color: #f8f8f8; color: #333; } label { display: block; margin-bottom: 5px; font-weight: bold; } input[type=text], input[type=password] { width: 95%; padding: 10px; margin-bottom: 15px; border: 1px solid #ccc; border-radius: 5px; font-size: 16px; } button { padding: 12px 20px; background-color: #007aff; color: white; border: none; border-radius: 8px; cursor: pointer; font-size: 16px; width: 100%; margin-top: 10px; } button:hover { background-color: #0056b3; } .error { color: red; font-size: 0.9em; margin-top: -10px; margin-bottom: 10px; } h2 { margin-top: 0; color: #111; } p { color: #555; } .info { font-size: 0.9em; color: #666; margin-bottom: 15px; } `; const urlValue = existingUrl ? `value="${escapeHtml(existingUrl)}"` : ""; const tokenPlaceholder = existingToken ? `placeholder="Exists (Enter new to change)"` : `placeholder="Enter Memos Token"`; const openaiKeyPlaceholder = existingOpenAIKey ? `placeholder="Exists (Enter new to change)"` : `placeholder="Enter OpenAI Key"`;
    return ` <!DOCTYPE html><html><head><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Memos Configuration</title><style>${css}</style></head> <body><h2>Memos Configuration</h2><p>Enter your Memos instance URL, Access Token (OpenAPI), and your OpenAI API Key.</p> <div class="info">Existing tokens/keys are not shown. Enter a new value only if you need to change it. Leave blank to keep the existing value (if any).</div> <form id="configForm"><label for="memosUrl">Memos URL:</label><input type="text" id="memosUrl" name="memosUrl" ${urlValue} required placeholder="https://your-memos.com"><div id="urlError" class="error" style="display: none;"></div> <label for="accessToken">Access Token:</label><input type="password" id="accessToken" name="accessToken" ${tokenPlaceholder} ><div id="tokenError" class="error" style="display: none;"></div> <label for="openaiKey">OpenAI API Key:</label><input type="password" id="openaiKey" name="openaiKey" ${openaiKeyPlaceholder}><div id="openaiError" class="error" style="display: none;"></div> <button type="submit">Save Configuration</button></form> <script> function initializeForm() { try { const form=document.getElementById('configForm'),urlInput=document.getElementById('memosUrl'),tokenInput=document.getElementById('accessToken'),openaiInput=document.getElementById('openaiKey'),urlError=document.getElementById('urlError'),tokenError=document.getElementById('tokenError'),openaiError=document.getElementById('openaiError'); if(!form||!urlInput||!tokenInput||!openaiInput||!urlError||!tokenError||!openaiError){console.error("Config form elements not found.");alert("Error initializing config form elements.");if(typeof completion==='function')completion({error:"Initialization failed: Elements missing"});return;} form.addEventListener('submit',(event)=>{ event.preventDefault();urlError.style.display='none';tokenError.style.display='none';openaiError.style.display='none';let isValid=true;const url=urlInput.value.trim(),newToken=tokenInput.value.trim(),newOpenaiApiKey=openaiInput.value.trim();if(!url){urlError.textContent='Memos URL is required.';urlError.style.display='block';isValid=false;}else if(!url.toLowerCase().startsWith('http://')&&!url.toLowerCase().startsWith('https://')){urlError.textContent='URL must start with http:// or https://';urlError.style.display='block';isValid=false;} if(isValid){if(typeof completion==='function'){completion({action:'submit',data:{url:url,token:newToken||null,openaiApiKey:newOpenaiApiKey||null}});}else{console.error('CRITICAL: completion function unavailable!');alert('Error: Cannot submit config form.');}} }); console.log("Config form initialized."); } catch (initError) { console.error("Error during config form initialization:", initError); alert("A critical error occurred setting up the configuration form."); if(typeof completion==='function')completion({error:"Initialization crashed",details:initError.message}); } } </script></body></html>`;
}

/**
 * Generates HTML for the main text input form with Compose field and Common Options.
 * Includes focus tracking and cursor insertion logic.
 * @param {string} [prefillText=''] - Text to pre-fill the main content textarea.
 * @returns {string} HTML content for the input form.
 */
function generateInputFormHtml(prefillText = "") {
    const css = `
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; padding: 15px; display: flex; flex-direction: column; height: 95vh; background-color: #f8f8f8; color: #333; }
        textarea { width: 95%; padding: 10px; margin-bottom: 10px; border: 1px solid #ccc; border-radius: 8px; font-size: 16px; resize: none; }
        #memoContent { flex-grow: 1; margin-bottom: 15px; }
        #composeInstructions { height: 60px; margin-bottom: 15px; }
        label { display: block; margin-bottom: 5px; font-weight: bold; font-size: 0.9em; color: #555; }
        .button-bar { display: flex; gap: 10px; margin-bottom: 15px; }
        .button-bar button { flex-grow: 1; padding: 10px 15px; background-color: #e0e0e0; color: #333; border: 1px solid #ccc; border-radius: 8px; cursor: pointer; font-size: 14px; }
        .button-bar button:hover { background-color: #d0d0d0; }
        button[type=submit] { padding: 12px 20px; background-color: #007aff; color: white; border: none; border-radius: 8px; cursor: pointer; font-size: 16px; width: 100%; margin-top: auto; }
        button[type=submit]:hover { background-color: #0056b3; }
        .options-section { margin-bottom: 15px; }
        .options-section label { font-weight: bold; font-size: 0.9em; color: #555; margin-bottom: 8px; }
        .common-options { display: flex; flex-wrap: wrap; gap: 10px; margin-bottom: 10px; }
        .common-options div { display: flex; align-items: center; }
        .common-options label { margin-left: 4px; font-weight: normal; font-size: 0.9em; }
        .ai-toggle { display: flex; align-items: center; }
        .ai-toggle label { margin-left: 8px; font-weight: normal; }
        input[type=checkbox] { width: 18px; height: 18px; }
        h2 { margin-top: 0; color: #111; }
        .clipboard-notice { font-size: 0.9em; color: #666; margin-bottom: 10px; }
        form { display: flex; flex-direction: column; flex-grow: 1; }
    `;

    const shareSheetNotice = prefillText ? `<div class="clipboard-notice">Text pre-filled from Share Sheet.</div>` : "";
    const escapedPrefillText = escapeHtml(prefillText);
    let commonOptionsHtml = '<label>Common Tasks:</label><div class="common-options">';
    COMMON_AI_TASKS.forEach(task => { const id = `common-opt-${task.value}`; commonOptionsHtml += `<div><input type="checkbox" id="${id}" name="commonOptions" value="${task.value}"><label for="${id}">${escapeHtml(task.label)}</label></div>`; });
    commonOptionsHtml += '</div>';
    const aiToggleHtml = `<div class="ai-toggle"><input type="checkbox" id="useAi" name="useAi" checked><label for="useAi">Process with AI</label></div>`;

    return `
    <!DOCTYPE html><html><head><meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no"><title>Enter Memo Content</title><style>${css}</style></head>
    <body><h2>Enter Memo Content</h2>${shareSheetNotice}
    <form id="inputForm">
        <label for="memoContent">Content:</label>
        <textarea id="memoContent" name="memoContent" placeholder="Type, paste, or dictate content here..." required onfocus="window.activeTextAreaId = this.id">${escapedPrefillText}</textarea>

        <div class="options-section">
             ${aiToggleHtml}
             ${commonOptionsHtml}
        </div>

        <label for="composeInstructions">Custom Instructions (Optional):</label>
        <textarea id="composeInstructions" name="composeInstructions" placeholder="e.g., Summarize, make this more formal..." onfocus="window.activeTextAreaId = this.id"></textarea>

        <div class="button-bar"><button type="button" id="pasteButton">Paste</button><button type="button" id="dictateButton">Dictate</button></div>

        <button type="submit">Add Memo</button>
    </form>
    <script>
        // Track focused element for dictation/paste
        window.activeTextAreaId = 'memoContent'; // Default

        // Function to insert text at cursor position
        function updateSpecificTextArea(targetId, textToInsert) {
            const textarea = document.getElementById(targetId);
            if (textarea && textToInsert != null) {
                const start = textarea.selectionStart;
                const end = textarea.selectionEnd;
                const currentText = textarea.value;
                const before = currentText.substring(0, start);
                const after = currentText.substring(end, currentText.length);

                // Insert the text (with spaces if inserting between words)
                let textWithSpacing = textToInsert;
                // Add leading space if not at start and previous char isn't space/newline
                if (start > 0 && !/\\s/.test(before.slice(-1))) {
                    textWithSpacing = " " + textWithSpacing;
                }
                 // Add trailing space if not at end and next char isn't space/newline
                if (end < currentText.length && !/\\s/.test(after.charAt(0))) {
                     textWithSpacing += " ";
                }

                textarea.value = before + textWithSpacing + after;

                // Set cursor position after inserted text
                const newCursorPos = start + textWithSpacing.length;
                textarea.selectionStart = newCursorPos;
                textarea.selectionEnd = newCursorPos;

                textarea.focus(); // Keep focus
                console.log(\`Text inserted into '\${targetId}' at position \${start}.\`);

                // Trigger input event for frameworks if needed (optional)
                // textarea.dispatchEvent(new Event('input', { bubbles: true }));

            } else {
                console.error(\`Could not find text area with ID '\${targetId}' or text was null.\`);
            }
        }

        // Legacy function (not really needed now but safe to keep)
        function updateTextArea(text) {
             updateSpecificTextArea('memoContent', text);
        }

        function initializeForm(){try{const t=document.getElementById("inputForm"),e=document.getElementById("memoContent"),o=document.getElementById("composeInstructions"),n=document.getElementById("useAi"),c=document.getElementById("pasteButton"),l=document.getElementById("dictateButton");if(!t||!e||!o||!n||!c||!l)return console.error("Required form elements not found."),alert("Error initializing form elements."),void(typeof completion=="function"&&completion({error:"Initialization failed: Elements missing"}));t.addEventListener("submit",t=>{t.preventDefault();const a=e.value.trim(),i=o.value.trim(),s=n.checked,r=[];document.querySelectorAll('input[name="commonOptions"]:checked').forEach(t=>{r.push(t.value)});a||i||r.length>0?typeof completion=="function"?completion({action:"submit",data:{text:a,compose:i,useAi:s,commonOptions:r}}):(console.error("CRITICAL: completion unavailable!"),alert("Error: Cannot submit form.")):alert("Please enter content, instructions, or select a common task.")}),c.addEventListener("click",()=>{console.log("Paste button clicked."),typeof completion=="function"?completion({action:"paste"}):(console.error("CRITICAL: completion unavailable!"),alert("Error: Cannot request paste."))}),l.addEventListener("click",()=>{console.log("Dictate button clicked."),typeof completion=="function"?completion({action:"dictate"}):(console.error("CRITICAL: completion unavailable!"),alert("Error: Cannot request dictation."))}),e.focus(),console.log("Input form initialized.")}catch(t){console.error("Error during input form initialization:",t),alert("A critical error occurred setting up the input form."),typeof completion=="function"&&completion({error:"Initialization crashed",details:t.message})}}
    </script></body></html>`;
}


/**
 * Generates HTML to display the parsed AI plan for review, using proposals with diff styling.
 * Removed placeholder comments.
 * @param {object} parsedPlanData - The structured plan object from parseAiXmlResponse.
 * @param {string} originalContent - The original user input text.
 * @returns {string} HTML content string.
 */
function generatePlanReviewHtml(parsedPlanData, originalContent = "") {
    const css = `
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; padding: 15px; background-color: #f8f8f8; color: #333; }
        .original-content-section { margin-bottom: 20px; border: 1px solid #ddd; border-radius: 8px; background-color: #f9f9f9; }
        .original-content-section details { padding: 5px 10px; }
        .original-content-section summary { font-weight: bold; cursor: pointer; padding: 5px 0; }
        .original-content-text { white-space: pre-wrap; word-wrap: break-word; max-height: 150px; overflow-y: auto; font-size: 0.9em; color: #444; background-color: #fff; padding: 8px; border-radius: 4px; border: 1px solid #eee; margin-top: 5px; }
        .plan-description { margin-bottom: 20px; padding: 10px; background-color: #eef; border-radius: 5px; border: 1px solid #dde; white-space: pre-wrap; }
        .proposal-block { margin-bottom: 15px; border: 1px solid #ccc; border-radius: 8px; background-color: white; overflow: hidden; }
        .proposal-header { background-color: #f0f0f0; padding: 8px 12px; border-bottom: 1px solid #ccc; display: flex; align-items: center; justify-content: space-between; }
        .proposal-title { font-weight: bold; }
        .proposal-include { display: flex; align-items: center; gap: 5px; font-size: 0.9em; }
        .proposal-content-area { padding: 10px 12px; }
        .proposal-description { font-style: italic; color: #555; margin-bottom: 8px; font-size: 0.9em; }
        .text-block { margin-bottom: 5px; }
        .text-label { font-size: 0.8em; color: #666; display: block; margin-bottom: 2px; }
        .text-content { white-space: pre-wrap; word-wrap: break-word; font-size: 0.95em; padding: 5px 8px; border-radius: 4px; border: 1px solid #eee; }
        .text-content.original { background-color: #ffebee; border-color: #ffcdd2; text-decoration: line-through; color: #d32f2f; }
        .text-content.added { background-color: #e8f5e9; border-color: #c8e6c9; color: #2e7d32; }
        .text-content.kept { background-color: #f5f5f5; border-color: #e0e0e0; }
        button[type=submit] { padding: 12px 20px; background-color: #007aff; color: white; border: none; border-radius: 8px; cursor: pointer; font-size: 16px; width: 100%; margin-top: 20px; }
        button[type=submit]:hover { background-color: #0056b3; }
        h2, h3 { margin-top: 0; color: #111; }
        p { color: #555; }
        form { margin-top: 10px; }
    `;

    const originalContentHtml = originalContent ? `
        <div class="original-content-section">
            <details> <summary>Show Original Input</summary> <div class="original-content-text">${escapeHtml(originalContent)}</div> </details>
        </div>` : "";

    let proposalsHtml = "";
    if (parsedPlanData?.proposals?.length > 0) {
        parsedPlanData.proposals.forEach((proposal, index) => {
            const proposalId = proposal.id || `prop-${index}`;
            const isChecked = proposal.action !== 'delete';
            let innerProposalContent = "";
            if (proposal.description) { innerProposalContent += `<div class="proposal-description">${escapeHtml(proposal.description)}</div>`; }
            if (proposal.original && ['replace', 'delete', 'keep'].includes(proposal.action)) { innerProposalContent += `<div class="text-block"><span class="text-label">Original${proposal.action === 'delete' ? ' (Deleted)' : (proposal.action === 'keep' ? ' (Kept)' : '')}:</span><div class="text-content original">${escapeHtml(proposal.original)}</div></div>`; }
            if (proposal.content && ['add', 'replace', 'keep'].includes(proposal.action)) { const label = proposal.action === 'replace' ? 'Proposed:' : (proposal.action === 'keep' ? 'Kept:' : 'Added:'); const contentClass = proposal.action === 'keep' ? 'text-content kept' : 'text-content added'; innerProposalContent += `<div class="text-block"><span class="text-label">${label}</span><div class="${contentClass}">${escapeHtml(proposal.content)}</div></div>`; }
            else if (proposal.action === 'add' && proposal.content) { innerProposalContent += `<div class="text-block"><span class="text-label">Added:</span><div class="text-content added">${escapeHtml(proposal.content)}</div></div>`; }

            proposalsHtml += `
            <div class="proposal-block">
              <div class="proposal-header"> <span class="proposal-title">Proposal ${index + 1} (${escapeHtml(proposal.action || 'suggest')})</span> <div class="proposal-include"> <input type="checkbox" class="proposal-toggle" id="${proposalId}" name="${proposalId}" data-proposal-id="${proposalId}" ${isChecked ? 'checked' : ''}> <label for="${proposalId}">Include</label> </div> </div>
              <div class="proposal-content-area"> ${innerProposalContent} </div>
            </div>`;
        });
    } else { /* ... (keep existing error/warning handling) ... */
        if (parsedPlanData.chatName === "AI Plan Error" || parsedPlanData.chatName === "AI Plan Warning") { proposalsHtml = `<p style="color: red;">${escapeHtml(parsedPlanData.planText || "Unknown error.")}</p>`; } else { proposalsHtml = "<p>No specific proposals found in the plan.</p>"; }
    }

    const planDescriptionHtml = parsedPlanData.planText && !parsedPlanData.chatName?.includes("Error") && !parsedPlanData.chatName?.includes("Warning") ? `<div class="plan-description"><strong>Plan:</strong>\n${escapeHtml(parsedPlanData.planText)}</div>` : "";
    const chatNameHtml = parsedPlanData.chatName && !parsedPlanData.chatName?.includes("Error") && !parsedPlanData.chatName?.includes("Warning") ? `<h3>${escapeHtml(parsedPlanData.chatName)}</h3>` : (parsedPlanData.chatName ? `<h3 style="color: ${parsedPlanData.chatName.includes('Error') ? 'red' : 'orange'};">${escapeHtml(parsedPlanData.chatName)}</h3>` : "");
    const disableSubmit = parsedPlanData.chatName === "AI Plan Error";

    // Removed the placeholder comments
    return `
    <!DOCTYPE html><html><head><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Review AI Generated Plan</title><style>${css}</style></head>
    <body><h2>Review AI Generated Plan</h2>${chatNameHtml}
    ${originalContentHtml}
    <p>Review the proposals generated by the AI. Uncheck proposals you wish to exclude.</p>
    ${planDescriptionHtml}
    <form id="reviewForm">
        ${proposalsHtml}
        <button type="submit" ${disableSubmit ? 'disabled style="background-color: #aaa;"' : ''}>Finalize Memo</button>
    </form>
    <script>
    function initializeForm(){try{const e=document.getElementById("reviewForm");if(!e)return console.error("Review form not found."),alert("Error initializing review form."),void(typeof completion=="function"&&completion({error:"Initialization failed: Form missing"}));e.addEventListener("submit",e=>{e.preventDefault();const t=document.querySelectorAll(".proposal-toggle"),o=[];t.forEach(e=>{e.checked&&o.push(e.dataset.proposalId)});console.log("Included proposal IDs:",o),typeof completion=="function"?completion({action:"submit",data:{includedProposalIds:o}}):(console.error("CRITICAL: completion unavailable!"),alert("Error submitting choices."))}),console.log("AI Plan Review form initialized.")}catch(e){console.error("Error during review init:",e),alert("A critical error occurred setting up review form."),typeof completion=="function"&&completion({error:"Initialization crashed",details:e.message})}}
    </script></body></html>`;
}


/** Retrieves Memos configuration */
async function getConfig(forcePrompt = false) { /* ... (keep existing - stable) ... */
    console.log("Attempting to retrieve configuration from Keychain..."); let url = Keychain.contains(KEYCHAIN_URL_KEY) ? Keychain.get(KEYCHAIN_URL_KEY) : null; let token = Keychain.contains(KEYCHAIN_TOKEN_KEY) ? Keychain.get(KEYCHAIN_TOKEN_KEY) : null; let openaiApiKey = Keychain.contains(KEYCHAIN_OPENAI_KEY) ? Keychain.get(KEYCHAIN_OPENAI_KEY) : null; console.log(`Retrieved Memos URL: ${url ? 'Exists' : 'Not Found'}`); console.log(`Retrieved Memos Token: ${token ? 'Exists' : 'Not Found'}`); console.log(`Retrieved OpenAI Key: ${openaiApiKey ? `Exists (Length: ${openaiApiKey.length})` : 'Not Found or Empty'}`); if (url && !url.toLowerCase().startsWith("http")) { console.warn(`Invalid URL format stored: ${url}. Clearing.`); Keychain.remove(KEYCHAIN_URL_KEY); url = null; } if (openaiApiKey !== null && openaiApiKey.trim() === "") { console.warn("Stored OpenAI Key was empty string. Clearing."); openaiApiKey = null; if (Keychain.contains(KEYCHAIN_OPENAI_KEY)) Keychain.remove(KEYCHAIN_OPENAI_KEY); } console.log(`OpenAI Key after cleanup: ${openaiApiKey ? 'Exists' : 'null'}`); if (forcePrompt || !url || !token) { console.log(`Configuration prompt needed. Reason: ${forcePrompt ? 'Forced' : (!url ? 'Memos URL missing' : 'Memos Token missing')}`); const configHtml = generateConfigFormHtml(url, token, openaiApiKey); const result = await presentWebViewForm(configHtml, false); if (!result) { console.log("Configuration prompt cancelled."); throw new Error("Configuration cancelled."); } const newUrl = result.url, newToken = result.token, newOpenaiApiKey = result.openaiApiKey; console.log(`Form submitted - URL: ${newUrl}, NewTokenProvided: ${!!newToken}, NewOpenAIKeyProvided: ${!!newOpenaiApiKey} (Length: ${newOpenaiApiKey?.length ?? 0})`); if (!newUrl || (!newUrl.toLowerCase().startsWith('http://') && !newUrl.toLowerCase().startsWith('https://'))) { throw new Error("Invalid Memos URL provided."); } url = newUrl; Keychain.set(KEYCHAIN_URL_KEY, url); console.log("Saved Memos URL."); if (newToken) { token = newToken; Keychain.set(KEYCHAIN_TOKEN_KEY, token); console.log("Saved new Memos Token."); } else if (!token) { throw new Error("Memos Access Token is required."); } else { console.log("Memos Token field left blank, keeping existing."); } if (newOpenaiApiKey) { openaiApiKey = newOpenaiApiKey; console.log(`Attempting to save NEW OpenAI Key (length: ${openaiApiKey.length})...`); Keychain.set(KEYCHAIN_OPENAI_KEY, openaiApiKey); console.log("Saved new OpenAI API Key."); } else if (openaiApiKey && !newOpenaiApiKey) { console.log("OpenAI Key field blank, removing existing."); openaiApiKey = null; if (Keychain.contains(KEYCHAIN_OPENAI_KEY)) Keychain.remove(KEYCHAIN_OPENAI_KEY); } else if (!openaiApiKey && !newOpenaiApiKey) { console.log("No OpenAI API Key provided or saved."); openaiApiKey = null; } else { console.log("OpenAI Key field blank, keeping existing."); } console.log("Configuration processing complete after prompt."); } else { console.log("Configuration retrieved without prompt."); } if (!url || !token) { throw new Error("Configuration incomplete: Missing Memos URL or Token."); } console.log(`FINAL Config Check - URL: ${!!url}, Token: ${!!token}, OpenAI Key: ${openaiApiKey ? `Exists (Length: ${openaiApiKey.length})` : 'null'}`); return { url, token, openaiApiKey };
}

/** Gets text input from Share Sheet or WebView form */
async function getInputText() { /* ... (keep existing - stable) ... */
    console.log("Checking for input source..."); let initialText = ""; if (args.plainTexts?.length > 0) { const sharedText = args.plainTexts.join("\n").trim(); if (sharedText) { console.log("Using text from Share Sheet."); initialText = sharedText; } } else { console.log("No Share Sheet input found."); } console.log(`Presenting WebView form for text input (AI checkbox always shown).`); const inputHtml = generateInputFormHtml(initialText); const formData = await presentWebViewForm(inputHtml, false); if (!formData || typeof formData.text === "undefined" || typeof formData.compose === "undefined" || typeof formData.useAi === "undefined" || !Array.isArray(formData.commonOptions)) { console.log("Input cancelled or form did not return expected data structure."); return null; } if (formData.text.trim() === "" && formData.compose.trim() === "" && formData.commonOptions.length === 0) { console.log("No text, instructions, or common options provided."); return null; } console.log(`Input received. Text length: ${formData.text.trim().length}, Compose length: ${formData.compose.trim().length}, Use AI: ${formData.useAi}, Common Options: [${formData.commonOptions.join(', ')}]`); return { text: formData.text.trim(), compose: formData.compose.trim(), useAi: formData.useAi, commonOptions: formData.commonOptions };
}

/** Makes an authenticated request to an API */
async function makeApiRequest(url, method, headers, body = null, timeout = 60, serviceName = "API") { /* ... (keep existing - stable) ... */
    console.log(`Making ${serviceName} request: ${method} ${url}`); const req = new Request(url); req.method = method; req.headers = headers; req.timeoutInterval = timeout; req.allowInsecureRequest = url.startsWith("http://"); if (body) { req.body = JSON.stringify(body); console.log(`${serviceName} Request body: ${body.content ? `{"content": "[CENSORED, Length: ${body.content.length}]", ...}` : (body.messages ? `{"messages": "[CENSORED]", ...}`: JSON.stringify(body).substring(0, 100) + "...")}`); } try { let responseData, statusCode, responseText = ""; const expectJson = headers["Content-Type"]?.includes("json") || headers["Accept"]?.includes("json"); if (method.toUpperCase() === 'GET' || expectJson) { try { responseData = await req.loadJSON(); statusCode = req.response.statusCode; responseText = JSON.stringify(responseData); } catch (e) { console.warn(`${serviceName} loadJSON failed (Status: ${req.response?.statusCode}), trying loadString. Error: ${e.message}`); statusCode = req.response?.statusCode ?? 500; if (statusCode >= 200 && statusCode < 300) { responseText = await req.loadString(); responseData = responseText; console.log(`${serviceName} received non-JSON success response (Status: ${statusCode}).`); } else { responseText = await req.loadString().catch(() => ""); responseData = responseText; console.error(`${serviceName} loadJSON failed and status code ${statusCode} indicates error.`); } } } else { responseText = await req.loadString(); statusCode = req.response.statusCode; responseData = responseText; } console.log(`${serviceName} Response Status Code: ${statusCode}`); if (statusCode < 200 || statusCode >= 300) { console.error(`${serviceName} Error Response Body: ${responseText}`); let errorMessage = responseText; if (typeof responseData === 'object' && responseData !== null) { errorMessage = responseData.error?.message || responseData.message || JSON.stringify(responseData); } throw new Error(`${serviceName} Error ${statusCode}: ${errorMessage || "Unknown error"}`); } console.log(`${serviceName} request successful.`); return responseData; } catch (e) { if (e.message.startsWith(`${serviceName} Error`)) { throw e; } console.error(`${serviceName} Request Failed: ${method} ${url} - ${e}`); throw new Error(`${serviceName} Request Failed: ${e.message || e}`); }
}

/** Creates a new memo in Memos */
async function createMemo(config, title) { /* ... (keep existing - stable) ... */
    const endpoint = config.url.replace(/\/$/, "") + "/api/v1/memos"; const headers = { "Content-Type": "application/json", Authorization: `Bearer ${config.token}` }; const body = { content: title, visibility: "PRIVATE" }; console.log(`Creating memo with title: "${title}"`); return await makeApiRequest(endpoint, "POST", headers, body, 30, "Memos");
}

/** Requests a plan from OpenAI using the proposal-based XML format */
async function getAiPlanAsXml(apiKey, originalContent, userInstructions, commonOptions = []) { /* ... (keep existing - stable) ... */
    console.log("Requesting XML plan (proposal format) from OpenAI..."); const endpoint = "https://api.openai.com/v1/chat/completions"; const model = "gpt-4o"; const proposalXmlInstructions = ` ### Role - You are an assistant that processes user text and proposes structured modifications or additions based on user instructions. - Your *entire response* MUST be valid XML using the tags defined below. - Start directly with '<proposals>'. Do NOT include ANY text outside the XML structure. ### Input Interpretation - **Original Content**: The base text provided by the user. - **User Instructions**: Specific directions on how to modify or generate text. ### Behavior Rules 1.  **Content + Instructions**: Modify the 'Original Content' according to 'User Instructions'. Break changes into logical proposals (replace, add, delete). 2.  **Instructions Only**: Generate new content based *only* on 'User Instructions'. Use 'add' proposals. 3.  **Content Only**: Assume default instructions: "Fix grammar, spelling, and improve clarity". Modify the 'Original Content' accordingly using proposals. ### XML Structure <proposals> <plan>Optional overall plan or summary of changes.</plan> <proposal id="unique_id_1" type="paragraph|list_item|heading|etc" action="add|replace|delete|keep"> <description>Optional brief explanation of this proposal.</description> <original> === REQUIRED for 'replace' and 'delete'. The exact original text this proposal affects. Use === markers. === </original> <content> === REQUIRED for 'add', 'replace', 'keep'. The proposed text content. Use === markers. Empty for 'delete'. === </content> </proposal> ... </proposals> ### Tag Explanations & Requirements - **<proposals>**: Root element. REQUIRED. - **<plan>**: Optional summary. - **<proposal>**: Represents one distinct section/change. REQUIRED if changes are made. - **id**: Unique identifier (e.g., "prop-1", "item-apple"). REQUIRED. - **type**: Semantic type (e.g., "paragraph", "list_item", "heading", "sentence"). REQUIRED. - **action**: "add", "replace", "delete", "keep". REQUIRED. - **<description>**: Optional explanation. - **<original>**: REQUIRED for 'replace'/'delete'. Wrap text with ===. - **<content>**: REQUIRED for 'add'/'replace'/'keep'. Wrap text with ===. Empty for 'delete'. ### Examples (Illustrative) - **Shopping List (Instructions Only):** User Instructions: "apples, oranges, bananas". Result: 3 proposals with action="add", type="list_item". - **Fix Sentence (Content Only):** Original Content: "the quik fox". Result: 1 proposal action="replace", type="sentence", with <original> and corrected <content>. - **Summarize (Content + Instructions):** Original Content: [long text]. User Instructions: "Summarize this". Result: 1 proposal action="replace", type="paragraph", with original text and summarized content. ### Final Instructions - Adhere strictly to the XML format. Respond ONLY with XML. - Use appropriate actions ('add', 'replace', 'delete', 'keep'). - Provide required tags (<original> for replace/delete, <content> for add/replace/keep). - Use === markers correctly. - Break down changes logically. `;
    let combinedInstructions = ""; const hasCustomInstructions = userInstructions && userInstructions.trim().length > 0; const hasCommonOptions = commonOptions && commonOptions.length > 0; if (hasCommonOptions) { const selectedLabels = commonOptions.map(value => COMMON_AI_TASKS.find(task => task.value === value)?.label).filter(label => label); if (selectedLabels.length > 0) { combinedInstructions += `Apply these actions: ${selectedLabels.join(', ')}. `; } } if (hasCustomInstructions) { if (combinedInstructions.length > 0) { combinedInstructions += `\nAdditionally: ${userInstructions}`; } else { combinedInstructions = userInstructions; } } let behaviorRule = ""; if (originalContent && combinedInstructions) { behaviorRule = "Modify the 'Original Content' according to the 'User Instructions'."; } else if (combinedInstructions) { behaviorRule = "Generate new content based *only* on the 'User Instructions'."; } else if (originalContent) { behaviorRule = "Apply default improvements (fix grammar, spelling, clarity) to the 'Original Content'."; combinedInstructions = "(Default: Fix grammar, spelling, and improve clarity of the Original Content.)"; } else { behaviorRule = "Generate a short example note as no content or instructions were given."; combinedInstructions = "Create a short example note."; } let userPrompt = `Generate proposals in the specified XML format. ${behaviorRule}\n\n`; if (originalContent) { userPrompt += `**Original Content:**\n${originalContent}\n\n`; } if (combinedInstructions) { userPrompt += `**User Instructions:**\n${combinedInstructions}\n\n`; } const messages = [ { role: "system", content: proposalXmlInstructions }, { role: "user", content: userPrompt }, ]; const headers = { "Content-Type": "application/json", Authorization: `Bearer ${apiKey}` }; const body = { model: model, messages: messages, max_tokens: 3000, temperature: 0.4, n: 1, stop: null };
    try { const responseJson = await makeApiRequest(endpoint, "POST", headers, body, 120, "OpenAI"); if (!responseJson.choices?.[0]?.message?.content) { throw new Error("OpenAI response missing content."); } let xmlContent = responseJson.choices[0].message.content.trim(); console.log("OpenAI raw response received. Length:", xmlContent.length); console.log("Raw OpenAI XML Response:\n---\n" + xmlContent + "\n---"); if (xmlContent.startsWith("```xml")) { xmlContent = xmlContent.substring(6).replace(/```$/, "").trim(); console.log("Stripped markdown fences."); } if (!xmlContent.startsWith("<proposals>")) { console.warn("OpenAI response may not start with <proposals>:", xmlContent.substring(0,100)); } else { console.log("OpenAI response looks like valid proposal XML."); } return xmlContent; } catch (e) { console.error(`OpenAI Plan Generation Failed: ${e}`); throw new Error(`OpenAI Plan Generation Failed: ${e.message}`); }
}

/** Parses the AI-generated XML plan (proposal format) */
function parseAiXmlResponse(xmlString) { /* ... (keep existing - stable) ... */
    console.log("Parsing AI XML response (proposal format)..."); if (!xmlString || typeof xmlString !== 'string' || xmlString.trim() === '') { console.error("Cannot parse empty or invalid XML string."); return null; } try { const parser = new XMLParser(xmlString); let parsedData = { planText: null, proposals: [] }; let currentProposal = null; let currentTag = null; let accumulatedChars = ""; let parseError = null; parser.didStartElement = (name, attrs) => { currentTag = name.toLowerCase(); accumulatedChars = ""; if (currentTag === "proposal") { currentProposal = { id: attrs.id || `prop-${Date.now()}-${Math.random()}`, type: attrs.type || "unknown", action: attrs.action || "suggest", description: null, original: null, content: null, }; } }; parser.foundCharacters = (chars) => { if (currentTag) { accumulatedChars += chars; } }; parser.didEndElement = (name) => { const tagName = name.toLowerCase(); const trimmedChars = accumulatedChars.trim(); if (tagName === "plan") { parsedData.planText = trimmedChars; } else if (tagName === "proposal") { if (currentProposal) { parsedData.proposals.push(currentProposal); currentProposal = null; } } else if (currentProposal) { if (tagName === "description") { currentProposal.description = trimmedChars; } else if (tagName === "original") { currentProposal.original = trimmedChars.replace(/^===\s*|\s*===$/g, "").trim(); } else if (tagName === "content") { currentProposal.content = trimmedChars.replace(/^===\s*|\s*===$/g, "").trim(); } } currentTag = null; accumulatedChars = ""; }; parser.parseErrorOccurred = (line, column, message) => { parseError = `XML Parse Error at ${line}:${column}: ${message}`; console.error(parseError); return; }; const success = parser.parse(); if (!success || parseError) { console.error("XML parsing failed.", parseError || ""); return null; } if (parsedData.proposals.length === 0 && !parsedData.planText) { console.warn("XML parsed successfully, but no <plan> or <proposal> tags were found."); return { chatName: "Parsing Issue", planText: "Warning: The AI response was parsed, but contained no recognizable plan or proposals.", proposals: [] }; } console.log("XML parsing successful (proposal format)."); return parsedData; } catch (e) { console.error(`Error during XML parsing setup or execution: ${e}`); return null; }
}

/** Constructs the final memo text based on selected proposals */
function constructFinalMemoText(parsedPlanData, includedProposalIds) { /* ... (keep existing - stable) ... */
    if (!parsedPlanData || !parsedPlanData.proposals || !Array.isArray(includedProposalIds)) { console.error("Invalid input for constructing final memo text."); return "Error: Could not construct final memo text."; } let outputLines = []; let currentListType = null; parsedPlanData.proposals.forEach(proposal => { if (includedProposalIds.includes(proposal.id)) { let textToUse = ""; if (proposal.action === 'delete') { return; } else if (proposal.action === 'keep') { textToUse = proposal.original || proposal.content || ""; } else { textToUse = proposal.content || ""; } if (proposal.type === 'list_item') { if (currentListType !== 'list_item') { if (outputLines.length > 0 && currentListType !== null) { outputLines.push(""); } currentListType = 'list_item'; } outputLines.push(`- ${textToUse.trim()}`); } else { if (currentListType === 'list_item') { outputLines.push(""); } currentListType = proposal.type; outputLines.push(textToUse); if (proposal.type === 'heading') { outputLines.push(""); } } } if (proposal.type !== 'list_item') { currentListType = null; } }); return outputLines.join("\n").trim();
}

/** Adds a comment to an existing memo */
async function addCommentToMemo(config, memoId, commentText) { /* ... (keep existing - stable) ... */
    const endpoint = config.url.replace(/\/$/, "") + `/api/v1/memos/${memoId}/comments`; const headers = { "Content-Type": "application/json", Authorization: `Bearer ${config.token}` }; const body = { content: commentText }; console.log(`Adding comment to memo ID: ${memoId}`); return await makeApiRequest(endpoint, "POST", headers, body, 30, "Memos");
}

// --- Main Execution ---

(async () => {
  console.log("Starting Script...");
  let forceConfigPrompt = false;

  // --- Config Reset ---
  if (args.queryParameters?.resetConfig === "true") { /* ... (keep existing) ... */
    console.log("Reset configuration argument detected."); const confirmAlert = new Alert(); confirmAlert.title = "Reset Configuration?"; confirmAlert.message = "Are you sure you want to remove the saved Memos URL, Access Token, and OpenAI Key? You will be prompted to re-enter them."; confirmAlert.addAction("Reset"); confirmAlert.addCancelAction("Cancel"); const confirmation = await confirmAlert.presentAlert(); if (confirmation === 0) { console.log("Removing configuration from Keychain..."); if (Keychain.contains(KEYCHAIN_URL_KEY)) Keychain.remove(KEYCHAIN_URL_KEY); if (Keychain.contains(KEYCHAIN_TOKEN_KEY)) Keychain.remove(KEYCHAIN_TOKEN_KEY); if (Keychain.contains(KEYCHAIN_OPENAI_KEY)) Keychain.remove(KEYCHAIN_OPENAI_KEY); console.log("Configuration removed."); forceConfigPrompt = true; } else { console.log("Configuration reset cancelled."); Script.complete(); return; }
  }

  let config;
  let inputData; // { text, compose, useAi, commonOptions }
  let createdMemo;
  let memoId;
  let finalText;
  let planUsed = false;

  try {
    config = await getConfig(forceConfigPrompt);
    console.log("Initial config obtained.");

    inputData = await getInputText(); // Gets { text, compose, useAi, commonOptions }
    if (!inputData) { console.log("No input or cancelled. Exiting."); Script.complete(); return; }

    const originalContent = inputData.text;
    const composeInstructions = inputData.compose;
    const commonOptions = inputData.commonOptions;
    finalText = originalContent; // Default

    console.log("Original Content Input:", originalContent);
    console.log("Compose Instructions Input:", composeInstructions);
    console.log("Common Options Input:", commonOptions);

    // --- AI Plan Flow ---
    if (inputData.useAi) {
        console.log("User wants AI processing. Checking Key...");
        let hasValidOpenAIKey = typeof config.openaiApiKey === 'string' && config.openaiApiKey.trim().length > 0;

        if (!hasValidOpenAIKey) { /* ... (keep existing key prompt logic) ... */
            console.log("OpenAI Key missing. Prompting..."); const configureAlert = new Alert(); configureAlert.title = "OpenAI Key Required"; configureAlert.message = "Configure OpenAI API Key to process with AI."; configureAlert.addAction("Configure Now"); configureAlert.addCancelAction("Use Original Text"); const choice = await configureAlert.presentAlert(); if (choice === 0) { console.log("Forcing config prompt..."); try { config = await getConfig(true); hasValidOpenAIKey = typeof config.openaiApiKey === 'string' && config.openaiApiKey.trim().length > 0; if (!hasValidOpenAIKey) { console.log("Key still missing after config attempt."); const stillMissingAlert = new Alert(); stillMissingAlert.title = "Key Still Missing"; stillMissingAlert.message = "OpenAI Key not saved correctly. Using original text."; await stillMissingAlert.presentAlert(); } else { console.log("OpenAI Key configured."); } } catch (configError) { console.error("Error during forced config:", configError); hasValidOpenAIKey = false; const configFailAlert = new Alert(); configFailAlert.title = "Configuration Failed"; configFailAlert.message = `Config failed: ${configError.message}\n\nUsing original text.`; await configFailAlert.presentAlert(); } } else { console.log("User cancelled config. Using original text."); hasValidOpenAIKey = false; }
        }

        if (hasValidOpenAIKey) {
            console.log("Valid Key found. Generating AI proposals...");
            let processingAlert = null;
            let parsedPlan = null;
            try {
                processingAlert = new Alert(); processingAlert.title = "Generating AI Plan..."; processingAlert.message = "Please wait."; processingAlert.present();
                const rawXml = await getAiPlanAsXml(config.openaiApiKey, originalContent, composeInstructions, commonOptions);
                if (processingAlert?.dismiss) { try { processingAlert.dismiss(); } catch (e) { /* ignore */ } } processingAlert = null;
                parsedPlan = parseAiXmlResponse(rawXml);

                if (!parsedPlan) {
                    console.warn("Failed to parse AI response. Creating default error plan.");
                    parsedPlan = { chatName: "AI Plan Error", planText: "Error: AI response could not be parsed as valid XML.", proposals: [] };
                } else if (parsedPlan.proposals.length === 0 && !parsedPlan.planText) {
                     console.warn("AI response parsed but contained no plan or proposals.");
                     parsedPlan = { chatName: "AI Plan Warning", planText: "Warning: AI response parsed successfully but contained no actionable proposals.", proposals: [] };
                }

                console.log("AI plan ready for review. Asking via WebView.");
                const reviewHtml = generatePlanReviewHtml(parsedPlan, originalContent);
                const reviewResult = await presentWebViewForm(reviewHtml, true);

                if (!reviewResult || !reviewResult.includedProposalIds) {
                     console.log("Plan review cancelled or failed. Using original text.");
                     finalText = originalContent;
                } else {
                    if (parsedPlan.chatName !== "AI Plan Error" && parsedPlan.chatName !== "AI Plan Warning") {
                        finalText = constructFinalMemoText(parsedPlan, reviewResult.includedProposalIds);
                        planUsed = true;
                        console.log("User finalized choices from AI proposals.");
                    } else {
                         console.log("Review screen showed error/warning. Using original text.");
                         finalText = originalContent;
                    }
                }

            } catch (aiError) { /* ... (keep existing AI error handling, ensure finalText = originalContent) ... */
                if (processingAlert?.dismiss) { try { processingAlert.dismiss(); } catch (e) { /* ignore */ } } console.error(`AI Plan Generation/Processing Failed: ${aiError}`); const aiErrorAlert = new Alert(); aiErrorAlert.title = "AI Plan Error"; aiErrorAlert.message = `Failed to generate or process AI plan:\n${aiError.message}\n\nUse original text instead?`; aiErrorAlert.addAction("Use Original"); aiErrorAlert.addCancelAction("Cancel Script"); const errorChoice = await aiErrorAlert.presentAlert(); if (errorChoice === -1) { console.log("Script cancelled due to AI plan processing error."); Script.complete(); return; } console.log("Proceeding with original text after AI error."); finalText = originalContent;
            }
        } else { console.log("Skipping AI processing: No valid OpenAI Key."); finalText = originalContent; }
    } else { console.log("User did not select 'Process with AI'."); finalText = originalContent; }
    // --- End AI Plan Flow ---

    // --- Memos Creation ---
    console.log("Proceeding to create Memos entry...");
    const memoTitle = `Quick Capture - ${new Date().toLocaleString()}`;
    createdMemo = await createMemo(config, memoTitle);

    const nameParts = createdMemo?.name?.split('/'); memoId = nameParts ? nameParts[nameParts.length - 1] : null;
    if (!memoId || typeof memoId !== 'string' || memoId.trim() === '') { console.error("Failed to get valid memo ID string.", createdMemo); throw new Error(`Could not determine memo ID string from name: ${createdMemo?.name}`); }
    console.log(`Memo created successfully with ID: ${memoId}`);

    if (typeof finalText !== 'string' || finalText.trim() === '') { console.warn("Final text is empty. Sending original content instead."); finalText = originalContent; if (finalText.trim() === '') { finalText = "(Empty Note)"; } }

    await addCommentToMemo(config, memoId, finalText);
    console.log("Comment added successfully!");

    // --- Success Alert ---
    let showAlerts = !(args.runsInWidget);
    if (showAlerts) { /* ... (keep existing success alert logic) ... */
        const successAlert = new Alert(); successAlert.title = "Success"; successAlert.message = "Memo and comment added to Memos."; if (planUsed) { successAlert.message += "\n(Used AI generated plan)"; } await successAlert.presentAlert();
    } else { console.log("Running in widget context, skipping success alert."); }

  } catch (e) { /* ... (keep existing error handling) ... */
    console.error(`Script execution failed: ${e}`); let showAlerts = !(args.runsInWidget); if (showAlerts) { const errorAlert = new Alert(); errorAlert.title = "Error"; const errorMessage = e.message || "An unknown error occurred."; errorAlert.message = `Script failed: ${errorMessage}`; if (e.message) { if (e.message.includes("401")) { errorAlert.message += e.message.toLowerCase().includes("openai") ? "\n\nCheck OpenAI Key/Account." : "\n\nCheck Memos Token."; } else if (e.message.includes("404") && e.message.toLowerCase().includes("memos")) { errorAlert.message += "\n\nCheck Memos URL Path."; } else if (e.message.includes("ENOTFOUND") || e.message.includes("Could not connect") || e.message.includes("timed out")) { errorAlert.message += "\n\nCheck Network/URL Reachability."; } else if (e.message.toLowerCase().includes("openai") && e.message.toLowerCase().includes("quota")) { errorAlert.message += "\n\nCheck OpenAI Quota."; } else if (e.message.toLowerCase().includes("xml parse error") || e.message.toLowerCase().includes("valid xml")) { errorAlert.message += "\n\nAI response was not valid XML."; } else if (e.message.includes("Configuration incomplete") || e.message.includes("Configuration cancelled")) { errorAlert.message += "\n\nPlease ensure Memos URL and Token are configured correctly."; } else if (e.message.includes("ID string from name")) { errorAlert.message += "\n\nCould not parse Memo ID from API response." } } await errorAlert.presentAlert(); } else { console.log("Running in widget context, skipping error alert."); }
  } finally {
    console.log("Script finished.");
    Script.complete();
  }
})();
