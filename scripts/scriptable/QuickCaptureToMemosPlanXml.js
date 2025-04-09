// Variables used by Scriptable.
// These must be at the very top of the file. Do not edit.
// icon-color: blue; icon-glyph: tasks;

// Configuration Keys
const KEYCHAIN_URL_KEY = "memos_instance_url";
const KEYCHAIN_TOKEN_KEY = "memos_access_token";
const KEYCHAIN_OPENAI_KEY = "openai_api_key"; // Used for OpenAI

// --- Helper Functions ---

/** Basic HTML escaping function */
function escapeHtml(unsafe) { /* ... (keep existing) ... */
    if (typeof unsafe !== "string") return "";
    return unsafe
      .replace(/&/g, "&")
      .replace(/</g, "<")
      .replace(/>/g, ">")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "'");
}

/** Presents an HTML form in a WebView */
async function presentWebViewForm(htmlContent, fullscreen = false) { /* ... (keep existing from previous version) ... */
    console.log("Configuring interactive WebView form...");
    const wv = new WebView(); let isPresented = false;
    try {
        console.log("Loading HTML into WebView instance..."); await wv.loadHTML(htmlContent); console.log("HTML loaded.");
        if (!isPresented) { console.log(`Presenting WebView initially (fullscreen: ${fullscreen})...`); wv.present(fullscreen).catch(e => { console.error("Error during initial WebView presentation:", e); }); isPresented = true; console.log("WebView presentation initiated."); await new Promise(resolve => Timer.schedule(100, false, resolve)); }
        while (true) {
            console.log("WebView Loop: Setting up listener..."); const listenerScript = ` if (typeof initializeForm === 'function' && !window.formInitialized) { console.log("Calling initializeForm()..."); try { initializeForm(); window.formInitialized = true; } catch (initErr) { console.error("Error executing initializeForm():", initErr); if (typeof completion === 'function') { completion({ error: "Form init failed", details: initErr.message }); } else { console.error("CRITICAL: completion unavailable."); } } } else if (!window.formInitialized && typeof initializeForm !== 'function') { console.error("initializeForm not found."); if (typeof completion === 'function') { completion({ error: "Init function missing" }); } else { console.error("CRITICAL: completion unavailable."); } window.formInitialized = true; } console.log("Listener active..."); `;
            let result;
            try { console.log("WebView Loop: Waiting for evaluateJavaScript..."); result = await wv.evaluateJavaScript(listenerScript, true); console.log("WebView Loop: evaluateJavaScript resolved:", result); }
            catch (e) { console.log(`WebView Loop: evaluateJavaScript caught error: ${e}`); console.log("Assuming dismissal or critical JS failure."); return null; }
            if (result?.error) { console.error(`WebView Loop: Error from JS: ${result.error}`, result.details || ""); /* Optionally alert */ }
            else if (result?.action) {
                switch (result.action) {
                    case "submit": console.log("WebView Loop: Received 'submit'. Returning data:", result.data); return result.data;
                    case "paste": console.log("WebView Loop: Received 'paste'."); const clipboardText = Pasteboard.pasteString() || ""; try { await wv.evaluateJavaScript(`updateTextArea(${JSON.stringify(clipboardText)})`, false); console.log("Sent paste data."); } catch (evalError) { console.error("Error sending paste data:", evalError); } break;
                    case "dictate": console.log("WebView Loop: Received 'dictate'."); try { const dictatedText = await Dictation.start(); if (dictatedText) { await wv.evaluateJavaScript(`updateTextArea(${JSON.stringify(dictatedText)})`, false); console.log("Sent dictate data."); } else { console.log("Dictation returned no text."); } } catch (dictationError) { console.error(`Dictation failed: ${dictationError}`); try { await wv.evaluateJavaScript(`alert('Dictation failed: ${escapeHtml(dictationError.message)}')`, false); } catch (alertError) { console.error("Failed to show dictation error alert:", alertError); let fallbackAlert = new Alert(); fallbackAlert.title = "Dictation Error"; fallbackAlert.message = `Dictation failed: ${dictationError.message}`; await fallbackAlert.presentAlert(); } } break;
                    default: console.warn(`WebView Loop: Unknown action: ${result.action}`); break;
                }
            } else { console.warn("WebView Loop: Unexpected result:", result); }
        }
    } catch (e) { console.error(`Error during interactive WebView operation: ${e}`); return null; }
}

/** Generates HTML for Memos configuration */
function generateConfigFormHtml(existingUrl, existingToken, existingOpenAIKey) { /* ... (keep existing) ... */
    const css = ` body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; padding: 15px; background-color: #f8f8f8; color: #333; } label { display: block; margin-bottom: 5px; font-weight: bold; } input[type=text], input[type=password] { width: 95%; padding: 10px; margin-bottom: 15px; border: 1px solid #ccc; border-radius: 5px; font-size: 16px; } button { padding: 12px 20px; background-color: #007aff; color: white; border: none; border-radius: 8px; cursor: pointer; font-size: 16px; width: 100%; margin-top: 10px; } button:hover { background-color: #0056b3; } .error { color: red; font-size: 0.9em; margin-top: -10px; margin-bottom: 10px; } h2 { margin-top: 0; color: #111; } p { color: #555; } .info { font-size: 0.9em; color: #666; margin-bottom: 15px; } `;
    const urlValue = existingUrl ? `value="${escapeHtml(existingUrl)}"` : ""; const tokenPlaceholder = existingToken ? `placeholder="Exists (Enter new to change)"` : `placeholder="Enter Memos Token"`; const openaiKeyPlaceholder = existingOpenAIKey ? `placeholder="Exists (Enter new to change)"` : `placeholder="Enter OpenAI Key"`;
    return ` <!DOCTYPE html><html><head><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Memos Configuration</title><style>${css}</style></head> <body><h2>Memos Configuration</h2><p>Enter your Memos instance URL, Access Token (OpenAPI), and your OpenAI API Key.</p> <div class="info">Existing tokens/keys are not shown. Enter a new value only if you need to change it. Leave blank to keep the existing value (if any).</div> <form id="configForm"><label for="memosUrl">Memos URL:</label><input type="text" id="memosUrl" name="memosUrl" ${urlValue} required placeholder="https://your-memos.com"><div id="urlError" class="error" style="display: none;"></div> <label for="accessToken">Access Token:</label><input type="password" id="accessToken" name="accessToken" ${tokenPlaceholder} ><div id="tokenError" class="error" style="display: none;"></div> <label for="openaiKey">OpenAI API Key:</label><input type="password" id="openaiKey" name="openaiKey" ${openaiKeyPlaceholder}><div id="openaiError" class="error" style="display: none;"></div> <button type="submit">Save Configuration</button></form> <script> function initializeForm() { try { const form=document.getElementById('configForm'),urlInput=document.getElementById('memosUrl'),tokenInput=document.getElementById('accessToken'),openaiInput=document.getElementById('openaiKey'),urlError=document.getElementById('urlError'),tokenError=document.getElementById('tokenError'),openaiError=document.getElementById('openaiError'); if(!form||!urlInput||!tokenInput||!openaiInput||!urlError||!tokenError||!openaiError){console.error("Config form elements not found.");alert("Error initializing config form elements.");if(typeof completion==='function')completion({error:"Initialization failed: Elements missing"});return;} form.addEventListener('submit',(event)=>{ event.preventDefault();urlError.style.display='none';tokenError.style.display='none';openaiError.style.display='none';let isValid=true;const url=urlInput.value.trim(),newToken=tokenInput.value.trim(),newOpenaiApiKey=openaiInput.value.trim();if(!url){urlError.textContent='Memos URL is required.';urlError.style.display='block';isValid=false;}else if(!url.toLowerCase().startsWith('http://')&&!url.toLowerCase().startsWith('https://')){urlError.textContent='URL must start with http:// or https://';urlError.style.display='block';isValid=false;} if(isValid){if(typeof completion==='function'){completion({action:'submit',data:{url:url,token:newToken||null,openaiApiKey:newOpenaiApiKey||null}});}else{console.error('CRITICAL: completion function unavailable!');alert('Error: Cannot submit config form.');}} }); console.log("Config form initialized."); } catch (initError) { console.error("Error during config form initialization:", initError); alert("A critical error occurred setting up the configuration form."); if(typeof completion==='function')completion({error:"Initialization crashed",details:initError.message}); } } </script></body></html>`;
}

/** Generates HTML for the main text input form (AI checkbox ALWAYS shown) */
function generateInputFormHtml(prefillText = "") { /* ... (keep existing) ... */
    const css = ` body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; padding: 15px; display: flex; flex-direction: column; height: 95vh; background-color: #f8f8f8; color: #333; } textarea { flex-grow: 1; width: 95%; padding: 10px; margin-bottom: 15px; border: 1px solid #ccc; border-radius: 8px; font-size: 16px; resize: none; } .button-bar { display: flex; gap: 10px; margin-bottom: 15px; } .button-bar button { flex-grow: 1; padding: 10px 15px; background-color: #e0e0e0; color: #333; border: 1px solid #ccc; border-radius: 8px; cursor: pointer; font-size: 14px; } .button-bar button:hover { background-color: #d0d0d0; } button[type=submit] { padding: 12px 20px; background-color: #007aff; color: white; border: none; border-radius: 8px; cursor: pointer; font-size: 16px; width: 100%; margin-top: auto; } button[type=submit]:hover { background-color: #0056b3; } .options { margin-bottom: 15px; display: flex; align-items: center; } label[for=useAi] { margin-left: 8px; font-weight: normal; } input[type=checkbox] { width: 18px; height: 18px; } h2 { margin-top: 0; color: #111; } .clipboard-notice { font-size: 0.9em; color: #666; margin-bottom: 10px; } form { display: flex; flex-direction: column; flex-grow: 1; } `;
    const shareSheetNotice = prefillText ? `<div class="clipboard-notice">Text pre-filled from Share Sheet.</div>` : ""; const aiCheckboxHtml = `<div class="options"><input type="checkbox" id="useAi" name="useAi"><label for="useAi">Process with AI (Generate Plan)</label></div>`; const escapedPrefillText = escapeHtml(prefillText);
    return ` <!DOCTYPE html><html><head><meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no"><title>Enter Memo Content</title><style>${css}</style></head> <body><h2>Enter Memo Content</h2>${shareSheetNotice}<form id="inputForm"> <textarea id="memoContent" name="memoContent" placeholder="Type, paste, or dictate your memo content here..." required>${escapedPrefillText}</textarea> <div class="button-bar"><button type="button" id="pasteButton">Paste from Clipboard</button><button type="button" id="dictateButton">Start Dictation</button></div> ${aiCheckboxHtml} <button type="submit">Add Memo</button></form> <script> function updateTextArea(text){const t=document.getElementById('memoContent');if(t&&null!=text){const e=t.value;t.value=e?e+" "+text:text,t.focus(),console.log("Text area updated.")}else console.error("Could not find text area or text was null.")} function initializeForm(){try{const t=document.getElementById("inputForm"),e=document.getElementById("memoContent"),o=document.getElementById("useAi"),n=document.getElementById("pasteButton"),c=document.getElementById("dictateButton");if(!t||!e||!o||!n||!c)return console.error("Required form elements not found."),alert("Error initializing form elements."),void(typeof completion=="function"&&completion({error:"Initialization failed: Elements missing"}));t.addEventListener("submit",t=>{t.preventDefault();const n=e.value.trim(),c=o.checked;n?typeof completion=="function"?completion({action:"submit",data:{text:n,useAi:c}}):(console.error("CRITICAL: completion function unavailable!"),alert("Error: Cannot submit form.")):alert("Please enter some content.")}),n.addEventListener("click",()=>{console.log("Paste button clicked."),typeof completion=="function"?completion({action:"paste"}):(console.error("CRITICAL: completion function unavailable!"),alert("Error: Cannot request paste."))}),c.addEventListener("click",()=>{console.log("Dictate button clicked."),typeof completion=="function"?completion({action:"dictate"}):(console.error("CRITICAL: completion function unavailable!"),alert("Error: Cannot request dictation."))}),e.focus(),console.log("Input form initialized.")}catch(t){console.error("Error during input form initialization:",t),alert("A critical error occurred setting up the input form."),typeof completion=="function"&&completion({error:"Initialization crashed",details:t.message})}} </script></body></html>`;
}

/**
 * Generates HTML to display the parsed AI plan for review, using proposals.
 * @param {object} parsedPlanData - The structured plan object from parseAiXmlResponse.
 * @returns {string} HTML content string.
 */
function generatePlanReviewHtml(parsedPlanData) {
    const css = `
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; padding: 15px; background-color: #f8f8f8; color: #333; }
        .plan-description { margin-bottom: 20px; padding: 10px; background-color: #eef; border-radius: 5px; border: 1px solid #dde; white-space: pre-wrap; }
        .proposal-block { margin-bottom: 15px; border: 1px solid #ccc; border-radius: 8px; background-color: white; overflow: hidden; }
        .proposal-header { background-color: #f0f0f0; padding: 8px 12px; border-bottom: 1px solid #ccc; display: flex; align-items: center; justify-content: space-between; }
        .proposal-title { font-weight: bold; }
        .proposal-include { display: flex; align-items: center; gap: 5px; font-size: 0.9em; }
        .proposal-content { padding: 10px 12px; }
        .proposal-description { font-style: italic; color: #555; margin-bottom: 8px; font-size: 0.9em; }
        .text-content { white-space: pre-wrap; word-wrap: break-word; font-size: 0.95em; }
        .text-content.original { background-color: #fff9c4; padding: 5px; border-radius: 3px; margin-bottom: 5px; border: 1px dashed #eee; } /* Light yellow for original */
        .text-content.added { background-color: #e8f5e9; padding: 5px; border-radius: 3px; border: 1px dashed #c8e6c9; } /* Light green for added */
        .text-content.deleted { background-color: #ffebee; padding: 5px; border-radius: 3px; text-decoration: line-through; color: #777; border: 1px dashed #ffcdd2; } /* Light red for deleted */
        button[type=submit] { padding: 12px 20px; background-color: #007aff; color: white; border: none; border-radius: 8px; cursor: pointer; font-size: 16px; width: 100%; margin-top: 20px; }
        button[type=submit]:hover { background-color: #0056b3; }
        h2, h3 { margin-top: 0; color: #111; }
        p { color: #555; }
        form { margin-top: 10px; } /* Add margin to form */
    `;

    let proposalsHtml = "";
    if (parsedPlanData?.proposals?.length > 0) {
        parsedPlanData.proposals.forEach((proposal, index) => {
            const proposalId = proposal.id || `prop-${index}`; // Ensure an ID
            proposalsHtml += `
            <div class="proposal-block">
              <div class="proposal-header">
                <span class="proposal-title">Proposal ${index + 1} (${escapeHtml(proposal.action || 'suggest')})</span>
                <div class="proposal-include">
                  <input type="checkbox" class="proposal-toggle" id="${proposalId}" name="${proposalId}" data-proposal-id="${proposalId}" checked>
                  <label for="${proposalId}">Include</label>
                </div>
              </div>
              <div class="proposal-content">
          `;
            if (proposal.description) {
                proposalsHtml += `<div class="proposal-description">${escapeHtml(proposal.description)}</div>`;
            }
            if (proposal.original) {
                proposalsHtml += `<div><small>Original:</small><div class="text-content original">${escapeHtml(proposal.original)}</div></div>`;
            }
            if (proposal.content) {
                 // Apply different style based on action
                 let contentClass = "text-content";
                 if (proposal.action === 'add') contentClass += ' added';
                 if (proposal.action === 'delete') contentClass += ' deleted';
                 // If action is replace, maybe show both original and content distinctly? For now, just show content.
                proposalsHtml += `<div><small>${proposal.original ? 'Proposed:' : 'Content:'}</small><div class="${contentClass}">${escapeHtml(proposal.content)}</div></div>`;
            }
            proposalsHtml += `</div></div>`; // Close content and block
        });
    } else {
        // Handle the case where the plan itself is an error message
        if (parsedPlanData.chatName === "AI Plan Error") {
             proposalsHtml = `<p style="color: red;">${escapeHtml(parsedPlanData.planText)}</p>`;
        } else {
             proposalsHtml = "<p>No specific proposals found in the plan.</p>";
        }
    }

    const planDescriptionHtml = parsedPlanData.planText && parsedPlanData.chatName !== "AI Plan Error"
        ? `<div class="plan-description"><strong>Plan:</strong>\n${escapeHtml(parsedPlanData.planText)}</div>`
        : ""; // Don't show generic "No description" if it's an error plan

    const chatNameHtml = parsedPlanData.chatName && parsedPlanData.chatName !== "AI Plan Error"
        ? `<h3>${escapeHtml(parsedPlanData.chatName)}</h3>`
        : (parsedPlanData.chatName === "AI Plan Error" ? `<h3 style="color: red;">${escapeHtml(parsedPlanData.chatName)}</h3>` : "");


    // Determine if we should disable the submit button (e.g., if it's an error plan)
    const disableSubmit = parsedPlanData.chatName === "AI Plan Error";

    return `
    <!DOCTYPE html><html><head><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Review AI Generated Plan</title><style>${css}</style></head>
    <body><h2>Review AI Generated Plan</h2>${chatNameHtml}
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
async function getConfig(forcePrompt = false) { /* ... (keep existing) ... */
    console.log("Attempting to retrieve configuration from Keychain..."); let url = Keychain.contains(KEYCHAIN_URL_KEY) ? Keychain.get(KEYCHAIN_URL_KEY) : null; let token = Keychain.contains(KEYCHAIN_TOKEN_KEY) ? Keychain.get(KEYCHAIN_TOKEN_KEY) : null; let openaiApiKey = Keychain.contains(KEYCHAIN_OPENAI_KEY) ? Keychain.get(KEYCHAIN_OPENAI_KEY) : null; console.log(`Retrieved Memos URL: ${url ? 'Exists' : 'Not Found'}`); console.log(`Retrieved Memos Token: ${token ? 'Exists' : 'Not Found'}`); console.log(`Retrieved OpenAI Key: ${openaiApiKey ? `Exists (Length: ${openaiApiKey.length})` : 'Not Found or Empty'}`); if (url && !url.toLowerCase().startsWith("http")) { console.warn(`Invalid URL format stored: ${url}. Clearing.`); Keychain.remove(KEYCHAIN_URL_KEY); url = null; } if (openaiApiKey !== null && openaiApiKey.trim() === "") { console.warn("Stored OpenAI Key was empty string. Clearing."); openaiApiKey = null; if (Keychain.contains(KEYCHAIN_OPENAI_KEY)) Keychain.remove(KEYCHAIN_OPENAI_KEY); } console.log(`OpenAI Key after cleanup: ${openaiApiKey ? 'Exists' : 'null'}`); if (forcePrompt || !url || !token) { console.log(`Configuration prompt needed. Reason: ${forcePrompt ? 'Forced' : (!url ? 'Memos URL missing' : 'Memos Token missing')}`); const configHtml = generateConfigFormHtml(url, token, openaiApiKey); const result = await presentWebViewForm(configHtml, false); if (!result) { console.log("Configuration prompt cancelled."); throw new Error("Configuration cancelled."); } const newUrl = result.url, newToken = result.token, newOpenaiApiKey = result.openaiApiKey; console.log(`Form submitted - URL: ${newUrl}, NewTokenProvided: ${!!newToken}, NewOpenAIKeyProvided: ${!!newOpenaiApiKey} (Length: ${newOpenaiApiKey?.length ?? 0})`); if (!newUrl || (!newUrl.toLowerCase().startsWith('http://') && !newUrl.toLowerCase().startsWith('https://'))) { throw new Error("Invalid Memos URL provided."); } url = newUrl; Keychain.set(KEYCHAIN_URL_KEY, url); console.log("Saved Memos URL."); if (newToken) { token = newToken; Keychain.set(KEYCHAIN_TOKEN_KEY, token); console.log("Saved new Memos Token."); } else if (!token) { throw new Error("Memos Access Token is required."); } else { console.log("Memos Token field left blank, keeping existing."); } if (newOpenaiApiKey) { openaiApiKey = newOpenaiApiKey; console.log(`Attempting to save NEW OpenAI Key (length: ${openaiApiKey.length})...`); Keychain.set(KEYCHAIN_OPENAI_KEY, openaiApiKey); console.log("Saved new OpenAI API Key."); } else if (openaiApiKey && !newOpenaiApiKey) { console.log("OpenAI Key field blank, removing existing."); openaiApiKey = null; if (Keychain.contains(KEYCHAIN_OPENAI_KEY)) Keychain.remove(KEYCHAIN_OPENAI_KEY); } else if (!openaiApiKey && !newOpenaiApiKey) { console.log("No OpenAI API Key provided or saved."); openaiApiKey = null; } else { console.log("OpenAI Key field blank, keeping existing."); } console.log("Configuration processing complete after prompt."); } else { console.log("Configuration retrieved without prompt."); } if (!url || !token) { throw new Error("Configuration incomplete: Missing Memos URL or Token."); } console.log(`FINAL Config Check - URL: ${!!url}, Token: ${!!token}, OpenAI Key: ${openaiApiKey ? `Exists (Length: ${openaiApiKey.length})` : 'null'}`); return { url, token, openaiApiKey };
}

/** Gets text input from Share Sheet or WebView form */
async function getInputText() { /* ... (keep existing) ... */
    console.log("Checking for input source..."); let initialText = ""; if (args.plainTexts?.length > 0) { const sharedText = args.plainTexts.join("\n").trim(); if (sharedText) { console.log("Using text from Share Sheet."); initialText = sharedText; } } else { console.log("No Share Sheet input found."); } console.log(`Presenting WebView form for text input (AI checkbox always shown).`); const inputHtml = generateInputFormHtml(initialText); const formData = await presentWebViewForm(inputHtml, false); if (!formData || typeof formData.text === "undefined" || typeof formData.useAi === "undefined") { console.log("Input cancelled or form did not return expected data."); return null; } if (formData.text.trim() === "") { console.log("No text entered."); return null; } console.log(`Input received. Text length: ${formData.text.trim().length}, Use AI checkbox state: ${formData.useAi}`); return { text: formData.text.trim(), useAi: formData.useAi };
}

/** Makes an authenticated request to an API */
async function makeApiRequest(url, method, headers, body = null, timeout = 60, serviceName = "API") { /* ... (keep existing) ... */
    console.log(`Making ${serviceName} request: ${method} ${url}`); const req = new Request(url); req.method = method; req.headers = headers; req.timeoutInterval = timeout; req.allowInsecureRequest = url.startsWith("http://"); if (body) { req.body = JSON.stringify(body); console.log(`${serviceName} Request body: ${body.content ? `{"content": "[CENSORED, Length: ${body.content.length}]", ...}` : (body.messages ? `{"messages": "[CENSORED]", ...}`: JSON.stringify(body).substring(0, 100) + "...")}`); } try { let responseData, statusCode, responseText = ""; const expectJson = headers["Content-Type"]?.includes("json") || headers["Accept"]?.includes("json"); if (method.toUpperCase() === 'GET' || expectJson) { try { responseData = await req.loadJSON(); statusCode = req.response.statusCode; responseText = JSON.stringify(responseData); } catch (e) { console.warn(`${serviceName} loadJSON failed (Status: ${req.response?.statusCode}), trying loadString. Error: ${e.message}`); statusCode = req.response?.statusCode ?? 500; if (statusCode >= 200 && statusCode < 300) { responseText = await req.loadString(); responseData = responseText; console.log(`${serviceName} received non-JSON success response (Status: ${statusCode}).`); } else { responseText = await req.loadString().catch(() => ""); responseData = responseText; console.error(`${serviceName} loadJSON failed and status code ${statusCode} indicates error.`); } } } else { responseText = await req.loadString(); statusCode = req.response.statusCode; responseData = responseText; } console.log(`${serviceName} Response Status Code: ${statusCode}`); if (statusCode < 200 || statusCode >= 300) { console.error(`${serviceName} Error Response Body: ${responseText}`); let errorMessage = responseText; if (typeof responseData === 'object' && responseData !== null) { errorMessage = responseData.error?.message || responseData.message || JSON.stringify(responseData); } throw new Error(`${serviceName} Error ${statusCode}: ${errorMessage || "Unknown error"}`); } console.log(`${serviceName} request successful.`); return responseData; } catch (e) { if (e.message.startsWith(`${serviceName} Error`)) { throw e; } console.error(`${serviceName} Request Failed: ${method} ${url} - ${e}`); throw new Error(`${serviceName} Request Failed: ${e.message || e}`); }
}

/** Creates a new memo in Memos */
async function createMemo(config, title) { /* ... (keep existing) ... */
    const endpoint = config.url.replace(/\/$/, "") + "/api/v1/memos"; const headers = { "Content-Type": "application/json", Authorization: `Bearer ${config.token}` }; const body = { content: title, visibility: "PRIVATE" }; console.log(`Creating memo with title: "${title}"`); return await makeApiRequest(endpoint, "POST", headers, body, 30, "Memos");
}

/**
 * Requests a plan from OpenAI using the new proposal-based XML format.
 * @param {string} apiKey - OpenAI API Key.
 * @param {string} userRequest - The user's input/request for the AI.
 * @returns {Promise<string>} Raw XML string response from OpenAI.
 * @throws {Error} If the API request fails or returns an error.
 */
async function getAiPlanAsXml(apiKey, userRequest) {
    console.log("Requesting XML plan (proposal format) from OpenAI...");
    const endpoint = "https://api.openai.com/v1/chat/completions";
    const model = "gpt-4o"; // Or "gpt-4-turbo"

    // NEW XML Formatting Instructions for Proposals
    const proposalXmlInstructions = `
### Role
- You are an assistant that processes user text and proposes structured modifications or additions.
- Your *entire response* MUST be valid XML using the tags defined below.
- Start directly with '<plan>' or '<proposals>'. Do NOT include ANY text outside the XML structure.

### XML Structure
<proposals>
  <plan>Optional overall plan or summary of changes.</plan>
  <proposal id="unique_id_1" type="paragraph|list_item|heading|etc" action="add|replace|delete|keep">
    <description>Optional brief explanation of this proposal.</description>
    <original>
===
Optional: The original text this proposal replaces or modifies. Use === markers.
===
    </original>
    <content>
===
The proposed text content. Use === markers. For delete actions, this can be empty or contain a note.
===
    </content>
  </proposal>
  <proposal id="unique_id_2" ...>
    ...
  </proposal>
  ...
</proposals>

### Tag Explanations
- **<proposals>**: Root element.
- **<plan>**: Optional. A high-level description of the overall goal or changes.
- **<proposal>**: Represents one distinct section or change.
    - **id**: A unique identifier for this proposal (e.g., "prop-1", "item-apple"). REQUIRED.
    - **type**: The semantic type of the content (e.g., "paragraph", "list_item", "heading", "sentence"). REQUIRED.
    - **action**: What to do with this proposal ("add", "replace", "delete", "keep"). REQUIRED. "keep" means include the original text as-is.
- **<description>**: Optional. Explanation for this specific proposal.
- **<original>**: Optional. The text being replaced or modified. Use for context with "replace" or "delete". MUST be wrapped in === markers.
- **<content>**: The actual text content proposed. MUST be wrapped in === markers. Can be empty for "delete".

### Examples

**Example 1: Shopping List**
User Request: "create me a shopping list with apples, orange, and banasnas inside of it"
AI Response:
<proposals>
  <plan>Create a shopping list with the requested items.</plan>
  <proposal id="item-apples" type="list_item" action="add">
    <content>
===
Apples
===
    </content>
  </proposal>
  <proposal id="item-orange" type="list_item" action="add">
    <content>
===
Orange
===
    </content>
  </proposal>
  <proposal id="item-bananas" type="list_item" action="add">
    <content>
===
Bananas
===
    </content>
  </proposal>
</proposals>

**Example 2: Correcting a Sentence**
User Request: "Fix this: the quik brown fox jumpd over the lasy dog"
AI Response:
<proposals>
  <plan>Correct spelling and grammar in the sentence.</plan>
  <proposal id="sent-1-replace" type="sentence" action="replace">
    <description>Corrected spelling and grammar.</description>
    <original>
===
the quik brown fox jumpd over the lasy dog
===
    </original>
    <content>
===
The quick brown fox jumped over the lazy dog.
===
    </content>
  </proposal>
</proposals>

### Final Instructions
- Adhere strictly to the XML format.
- Provide meaningful 'id', 'type', and 'action' attributes.
- Use === markers correctly around <original> and <content> text.
- Break down the user's request into logical <proposal> blocks.
- Respond ONLY with the XML structure. No extra text before or after.
`;

    const messages = [
        { role: "system", content: proposalXmlInstructions },
        { role: "user", content: `Generate proposals in the specified XML format for the following text/request:\n\n${userRequest}` },
    ];
    const headers = { "Content-Type": "application/json", Authorization: `Bearer ${apiKey}` };
    const body = { model: model, messages: messages, max_tokens: 3000, temperature: 0.3, n: 1, stop: null };

    try {
        const responseJson = await makeApiRequest(endpoint, "POST", headers, body, 90, "OpenAI");
        if (!responseJson.choices?.[0]?.message?.content) { throw new Error("OpenAI response missing content."); }
        let xmlContent = responseJson.choices[0].message.content.trim();
        console.log("OpenAI raw response received. Length:", xmlContent.length);
        console.log("Raw OpenAI XML Response:\n" + xmlContent); // Log the raw response

        // Strip potential markdown fences
        if (xmlContent.startsWith("```xml")) { xmlContent = xmlContent.substring(6).replace(/```$/, "").trim(); console.log("Stripped markdown fences."); }

        if (!xmlContent.startsWith("<") || !xmlContent.endsWith(">")) { console.warn("OpenAI response may not be valid XML:", xmlContent); }
        else { console.log("OpenAI response looks like XML."); }
        return xmlContent;
    } catch (e) {
        console.error(`OpenAI Plan Generation Failed: ${e}`);
        throw new Error(`OpenAI Plan Generation Failed: ${e.message}`);
    }
}


/**
 * Parses the AI-generated XML plan (proposal format) into a JavaScript object.
 * @param {string} xmlString - The raw XML string from OpenAI.
 * @returns {object|null} Structured plan object or null on parsing error.
 */
function parseAiXmlResponse(xmlString) {
    console.log("Parsing AI XML response (proposal format)...");
    if (!xmlString || typeof xmlString !== 'string' || xmlString.trim() === '') { console.error("Cannot parse empty or invalid XML string."); return null; }
    try {
        const parser = new XMLParser(xmlString);
        // Adjusted structure: planText is optional, proposals is the main array
        let parsedData = { planText: null, proposals: [] };
        let currentProposal = null;
        let currentTag = null;
        let accumulatedChars = "";
        let parseError = null;

        parser.didStartElement = (name, attrs) => {
            currentTag = name.toLowerCase();
            accumulatedChars = "";
            // console.log(`Start Element: ${name}, Attrs: ${JSON.stringify(attrs)}`);
            if (currentTag === "proposal") {
                currentProposal = {
                    id: attrs.id || `prop-${Date.now()}-${Math.random()}`, // Generate fallback ID
                    type: attrs.type || "unknown",
                    action: attrs.action || "suggest",
                    description: null,
                    original: null,
                    content: null,
                };
            }
        };

        parser.foundCharacters = (chars) => { if (currentTag) { accumulatedChars += chars; } };

        parser.didEndElement = (name) => {
            const tagName = name.toLowerCase();
            const trimmedChars = accumulatedChars.trim();
            // console.log(`End Element: ${name}, Chars: "${trimmedChars}"`);

            if (tagName === "plan") {
                parsedData.planText = trimmedChars;
            } else if (tagName === "proposal") {
                if (currentProposal) {
                    // Basic validation: ensure content exists unless action is delete/keep?
                    // if (currentProposal.action !== 'delete' && currentProposal.action !== 'keep' && !currentProposal.content) {
                    //     console.warn("Proposal missing content for action:", currentProposal.action, currentProposal.id);
                    // }
                    parsedData.proposals.push(currentProposal);
                    currentProposal = null;
                }
            } else if (currentProposal) { // Handle tags within <proposal>
                if (tagName === "description") { currentProposal.description = trimmedChars; }
                else if (tagName === "original") { currentProposal.original = trimmedChars.replace(/^===\s*|\s*===$/g, "").trim(); }
                else if (tagName === "content") { currentProposal.content = trimmedChars.replace(/^===\s*|\s*===$/g, "").trim(); }
            }
            currentTag = null; accumulatedChars = "";
        };

        parser.parseErrorOccurred = (line, column, message) => { parseError = `XML Parse Error at ${line}:${column}: ${message}`; console.error(parseError); return; };

        const success = parser.parse();
        if (!success || parseError) { console.error("XML parsing failed.", parseError || ""); return null; }

        // Add check: If parsing succeeded but no proposals were found, maybe return null or specific error object?
        if (parsedData.proposals.length === 0 && !parsedData.planText) {
             console.warn("XML parsed successfully, but no <plan> or <proposal> tags were found.");
             // Return a default error object instead of null?
             return {
                 chatName: "Parsing Issue", // Use chatName for error indication
                 planText: "Warning: The AI response was parsed, but contained no recognizable plan or proposals.",
                 proposals: []
             };
        }

        console.log("XML parsing successful (proposal format).");
        // console.log("Parsed Data:", JSON.stringify(parsedData, null, 2));
        return parsedData;
    } catch (e) { console.error(`Error during XML parsing setup or execution: ${e}`); return null; }
}


/**
 * Constructs the final memo text based on selected proposals.
 * @param {object} parsedPlanData - The structured plan object containing proposals.
 * @param {string[]} includedProposalIds - Array of IDs for proposals to include.
 * @returns {string} Formatted final memo text string.
 */
function constructFinalMemoText(parsedPlanData, includedProposalIds) {
    if (!parsedPlanData || !parsedPlanData.proposals || !Array.isArray(includedProposalIds)) {
        console.error("Invalid input for constructing final memo text.");
        return "Error: Could not construct final memo text.";
    }

    let outputLines = [];
    let currentListType = null; // Track if we are in a list

    parsedPlanData.proposals.forEach(proposal => {
        // Check if this proposal should be included
        if (includedProposalIds.includes(proposal.id)) {
            let textToUse = "";
            if (proposal.action === 'delete') {
                // Skip deleted items entirely
                return;
            } else if (proposal.action === 'keep') {
                textToUse = proposal.original || ""; // Use original if keeping
            } else {
                // Use content for 'add', 'replace', or default 'suggest'
                textToUse = proposal.content || "";
            }

            // Handle list formatting
            if (proposal.type === 'list_item') {
                if (currentListType !== 'list_item') {
                    // Starting a new list (or switching to list)
                    // Add a newline before starting list if previous item wasn't list
                    if (outputLines.length > 0 && currentListType !== null) {
                         outputLines.push(""); // Add blank line separator
                    }
                    currentListType = 'list_item';
                }
                // Add list marker (e.g., bullet point)
                outputLines.push(`- ${textToUse.trim()}`);
            } else {
                // Not a list item
                if (currentListType === 'list_item') {
                    // Ending a list
                    outputLines.push(""); // Add blank line separator
                }
                currentListType = proposal.type; // Track current type
                // Add paragraph/heading/etc. as is (trimming might be too aggressive for code blocks)
                outputLines.push(textToUse);
                 // Add extra newline after headings?
                 if (proposal.type === 'heading') {
                     outputLines.push("");
                 }
            }
        } else {
             // If proposal is *not* included, check if we need to end a list
             if (currentListType === 'list_item' && proposal.type === 'list_item') {
                 // We were in a list, but skipped an item. Continue list logic doesn't apply here.
                 // We might need more complex logic if skipping items should break the list.
                 // For now, just reset list type if a non-list item follows.
             }
        }
         // Reset list type if the *next* item isn't a list item (handled in the 'else' block above)
         if (proposal.type !== 'list_item') {
             currentListType = null;
         }

    });

    return outputLines.join("\n").trim();
}


/** Adds a comment to an existing memo */
async function addCommentToMemo(config, memoId, commentText) { /* ... (keep existing) ... */
    const endpoint = config.url.replace(/\/$/, "") + `/api/v1/memos/${memoId}/comments`; const headers = { "Content-Type": "application/json", Authorization: `Bearer ${config.token}` }; const body = { content: commentText }; console.log(`Adding comment to memo ID: ${memoId}`); return await makeApiRequest(endpoint, "POST", headers, body, 30, "Memos");
}

// --- Main Execution ---

(async () => {
  console.log("Starting Interactive Quick Capture (with AI Plan) to Memos script...");
  let forceConfigPrompt = false;

  // --- Configuration Reset Logic ---
  if (args.queryParameters?.resetConfig === "true") { /* ... (keep existing) ... */
    console.log("Reset configuration argument detected."); const confirmAlert = new Alert(); confirmAlert.title = "Reset Configuration?"; confirmAlert.message = "Are you sure you want to remove the saved Memos URL, Access Token, and OpenAI Key? You will be prompted to re-enter them."; confirmAlert.addAction("Reset"); confirmAlert.addCancelAction("Cancel"); const confirmation = await confirmAlert.presentAlert(); if (confirmation === 0) { console.log("Removing configuration from Keychain..."); if (Keychain.contains(KEYCHAIN_URL_KEY)) Keychain.remove(KEYCHAIN_URL_KEY); if (Keychain.contains(KEYCHAIN_TOKEN_KEY)) Keychain.remove(KEYCHAIN_TOKEN_KEY); if (Keychain.contains(KEYCHAIN_OPENAI_KEY)) Keychain.remove(KEYCHAIN_OPENAI_KEY); console.log("Configuration removed."); forceConfigPrompt = true; } else { console.log("Configuration reset cancelled."); Script.complete(); return; }
  }

  let config;
  let inputData; // { text, useAi }
  let createdMemo;
  let memoId;
  let finalText;
  let planUsed = false; // Renamed from proposalUsed for clarity

  try {
    config = await getConfig(forceConfigPrompt);
    console.log("Initial configuration obtained.");

    inputData = await getInputText(); // Gets { text, useAi }

    if (!inputData) { console.log("No input text or cancelled. Exiting."); Script.complete(); return; }

    const originalInputText = inputData.text;
    finalText = originalInputText; // Default

    // --- AI Plan Generation Flow ---
    if (inputData.useAi) {
        console.log("User checked 'Process with AI'. Checking Key...");
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
                const rawXml = await getAiPlanAsXml(config.openaiApiKey, originalInputText);
                if (processingAlert?.dismiss) { try { processingAlert.dismiss(); } catch (e) { /* ignore */ } } processingAlert = null;

                parsedPlan = parseAiXmlResponse(rawXml);

                if (!parsedPlan) {
                    console.warn("Failed to parse AI response. Creating default error plan.");
                    parsedPlan = { chatName: "AI Plan Error", planText: "Error: AI response could not be parsed as valid XML.", proposals: [] };
                } else if (parsedPlan.proposals.length === 0 && !parsedPlan.planText) {
                     // Handle case where parsing succeeded but found nothing meaningful
                     console.warn("AI response parsed but contained no plan or proposals.");
                     parsedPlan = { chatName: "AI Plan Warning", planText: "Warning: AI response parsed successfully but contained no actionable proposals.", proposals: [] };
                }


                console.log("AI plan ready for review. Asking via WebView.");
                const reviewHtml = generatePlanReviewHtml(parsedPlan);
                const reviewResult = await presentWebViewForm(reviewHtml, true); // reviewResult = { includedProposalIds: [...] }

                // Check if review was cancelled or failed
                if (!reviewResult || !reviewResult.includedProposalIds) {
                     console.log("Plan review cancelled or failed. Reverting to original text.");
                     // finalText remains originalInputText
                } else {
                    // Construct final text ONLY if it wasn't an error plan shown
                    if (parsedPlan.chatName !== "AI Plan Error" && parsedPlan.chatName !== "AI Plan Warning") {
                        finalText = constructFinalMemoText(parsedPlan, reviewResult.includedProposalIds);
                        planUsed = true; // Mark that a valid plan was potentially used
                        console.log("User finalized choices from AI proposals.");
                    } else {
                         console.log("Review screen showed an error/warning. Reverting to original text.");
                         // finalText remains originalInputText
                    }
                }

            } catch (aiError) { /* ... (keep existing AI error handling) ... */
                if (processingAlert?.dismiss) { try { processingAlert.dismiss(); } catch (e) { /* ignore */ } } console.error(`AI Plan Generation/Processing Failed: ${aiError}`); const aiErrorAlert = new Alert(); aiErrorAlert.title = "AI Plan Error"; aiErrorAlert.message = `Failed to generate or process AI plan:\n${aiError.message}\n\nUse original text instead?`; aiErrorAlert.addAction("Use Original"); aiErrorAlert.addCancelAction("Cancel Script"); const errorChoice = await aiErrorAlert.presentAlert(); if (errorChoice === -1) { console.log("Script cancelled due to AI plan processing error."); Script.complete(); return; } console.log("Proceeding with original text after AI error.");
            }
        } else { console.log("Skipping AI processing: No valid OpenAI Key."); }
    } else { console.log("User did not select 'Process with AI'."); }
    // --- End AI Plan Generation Flow ---

    // --- Memos Creation ---
    console.log("Proceeding to create Memos entry...");
    const memoTitle = `Quick Capture - ${new Date().toLocaleString()}`;
    createdMemo = await createMemo(config, memoTitle);

    const nameParts = createdMemo?.name?.split('/'); memoId = nameParts ? nameParts[nameParts.length - 1] : null;
    if (!memoId || typeof memoId !== 'string' || memoId.trim() === '') { console.error("Failed to get valid memo ID string.", createdMemo); throw new Error(`Could not determine memo ID string from name: ${createdMemo?.name}`); }
    console.log(`Memo created successfully with ID: ${memoId}`);

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
