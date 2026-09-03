/* CONV-D Link Module
 * Reusable URL dispatcher for supported AI conversation pages.
 * It never fetches private conversation content itself; it opens the exact URL
 * in a Chromium tab so the authenticated page can be handled by CONV-D.
 */
(function(global){'use strict';
  var HOSTS=[
    /(^|\.)chatgpt\.com$/i,/\bclaude\.ai$/i,/\bgemini\.google\.com$/i,
    /\bcopilot\.microsoft\.com$/i,/\bperplexity\.ai$/i,/\bgrok\.com$/i,
    /\bchat\.deepseek\.com$/i,/\bpoe\.com$/i,/\bchat\.mistral\.ai$/i,
    /\byou\.com$/i,/\bmeta\.ai$/i,/\bchat\.qwen\.ai$/i,
    /\bhuggingface\.co$/i,/\bcharacter\.ai$/i
  ];
  function parse(raw){
    try{var u=new URL(String(raw||'').trim());if(u.protocol!=='https:')return null;for(var i=0;i<HOSTS.length;i++)if(HOSTS[i].test(u.hostname))return u;return null}catch(_){return null}
  }
  function open(raw){var u=parse(raw);if(!u)return Promise.reject(new Error('URL de conversa nao suportada.'));return chrome.tabs.create({url:u.href,active:true});}
  global.IZGITH_CONVD_LINK={parse:parse,open:open,hosts:HOSTS.length};
})(self);
