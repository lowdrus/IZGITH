const $=sel=>document.querySelector(sel);const state={jsonFile:null,htmlFile:null};
$("#fileJson").addEventListener("change",e=>{state.jsonFile=e.target.files[0]||null;});
$("#fileHtml").addEventListener("change",e=>{state.htmlFile=e.target.files[0]||null;});
$("#scrape").addEventListener("click",async()=>{try{const [tab]=await chrome.tabs.query({active:true,currentWindow:true});const resp=await chrome.tabs.sendMessage(tab.id,{fn:"SCRAPE_CHAT"});
const titleLike=$("#title").value.trim();await window.CONVERSATIONS_GPT.processData({titleLike,messages:resp?.messages||[],jsonFile:null,htmlFile:null});}catch(e){alert("Falha ao extrair da aba atual. Abra uma conversa do ChatGPT e tente novamente. "+e.message);}});
$("#import").addEventListener("click",async()=>{alert("Arquivos carregados. Agora clique em 'Processar e baixar ZIP'.");});
$("#run").addEventListener("click",async()=>{try{const titleLike=$("#title").value.trim();await window.CONVERSATIONS_GPT.processData({titleLike,messages:null,jsonFile:state.jsonFile,htmlFile:state.htmlFile});}catch(e){alert("Erro: "+e.message);}});