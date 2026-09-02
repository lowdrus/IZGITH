const LANG_MAP=[
"python","py","powershell","ps1","ps","bash","sh","shell","javascript","js","typescript","ts","html","css",
"json","xml","sql","java","kotlin","scala","groovy","ruby","rb","perl","pl","php","go","rust","rs","c","h","cpp",
"hpp","cs","swift","r","matlab","octave","julia","lua","dart","elixir","erlang","haskell","clojure","lisp","scheme",
"ocaml","fsharp","prolog","vb","vba","makefile","dockerfile","yaml","toml","ini","cfg","bat","cmd",
"tsx","jsx","svelte","vue","graphql","proto","thrift","latex","tex","markdown","md","rst","asm","nasm","arm","verilog",
"vhdl","solidity","nim","zig","ada","fortran","forth","reason","qml","tcl","awk","sed","fish","zsh","nushell"
];
function detectExt(code, langHint=""){const m=new Map([["python","py"],["py","py"],["powershell","ps1"],["ps1","ps1"],["ps","ps1"],
["bash","sh"],["sh","sh"],["shell","sh"],["javascript","js"],["js","js"],["typescript","ts"],["ts","ts"],["html","html"],["css","css"],
["json","json"],["xml","xml"],["sql","sql"],["java","java"],["cs","cs"],["c","c"],["cpp","cpp"],["hpp","hpp"],["h","h"],["go","go"],
["rust","rs"],["rs","rs"],["php","php"],["rb","rb"],["ruby","rb"],["kotlin","kt"],["kt","kt"],["swift","swift"],["r","r"],["julia","jl"],
["dart","dart"],["lua","lua"],["yaml","yml"],["toml","toml"],["ini","ini"],["cfg","cfg"],["md","md"],["markdown","md"],["bat","bat"],["cmd","cmd"]]);
const lang=(langHint||"").toLowerCase();if(m.has(lang))return m.get(lang);
const c=(code||"").trim();if(c.startsWith("#!")&&c.toLowerCase().includes("python"))return"py";
if(/^\s*import\s+\w+/.test(c)||/\bdef\s+\w+\s*\(/.test(c))return"py";
if(/Get-ChildItem|Write-Host|\bparam\b/i.test(c))return"ps1";
if(/^\s*</.test(c)&&/html/i.test(c))return"html";return"txt"}
function splitFences(text,msgIdx,files){const re=/```([\w+-]*)\n([\s\S]*?)```/g;let last=0,out="";let m,k=0;
while((m=re.exec(text))!==null){const before=text.slice(last,m.index);if(before)out+=before;const lang=(m[1]||"").trim().toLowerCase();
const code=m[2]||"";k++;const ext=detectExt(code,lang);const fname=`code_${String(msgIdx).padStart(3,'0')}_${String(k).padStart(3,'0')}.${ext}`;
files.push({name:fname,data:code});out+=`[Código extraído: ${fname}]`;last=re.lastIndex}out+=text.slice(last);return out}
function strToUint8(s){const a=new Uint8Array(s.length);for(let i=0;i<s.length;i++)a[i]=s.charCodeAt(i)&255;return a}
function makeCrc32Table(){const t=new Uint32Array(256);for(let i=0;i<256;i++){let c=i;for(let j=0;j<8;j++){c=(c&1)?(0xEDB88320^(c>>>1)):(c>>>1)}t[i]=c>>>0}return t}
const CRC_TABLE=makeCrc32Table();
function crc32(buf){let c=0xffffffff;for(let i=0;i<buf.length;i++){c=CRC_TABLE[(c^buf[i])&255]^(c>>>8)}return(c^0xffffffff)>>>0}
function u32(n){return new Uint8Array([n&255,(n>>>8)&255,(n>>>16)&255,(n>>>24)&255])}
function u16(n){return new Uint8Array([n&255,(n>>>8)&255])}
function cat(arrs){let len=0;arrs.forEach(a=>len+=a.length);const out=new Uint8Array(len);let o=0;arrs.forEach(a=>{out.set(a,o);o+=a.length});return out}
function buildZipStore(entries){const files=[];let offset=0;const cd=[];
entries.forEach(e=>{const name=strToUint8(e.name);const data=strToUint8(e.data);const crc=crc32(data);
const local=cat([strToUint8("PK\x03\x04"),u16(20),u16(0),u16(0),u16(0),u16(0),u32(crc),u32(data.length),u32(data.length),u16(name.length),u16(0),name]);
const rec=cat([local,data]);files.push(rec);
const central=cat([strToUint8("PK\x01\x02"),u16(20),u16(20),u16(0),u16(0),u16(0),u16(0),u32(crc),u32(data.length),u32(data.length),u16(name.length),u16(0),u16(0),u16(0),u16(0),u32(0),u32(offset),name]);
cd.push(central);offset+=rec.length});
const dir=cat(cd);const end=cat([strToUint8("PK\x05\x06"),u16(0),u16(0),u16(entries.length),u16(entries.length),u32(dir.length),u32(offset),u16(0)]);
return new Blob([cat([...files,dir,end])],{type:"application/zip"})}
async function processData({titleLike,messages,jsonFile,htmlFile}){
let convs=[],htmlText="";if(jsonFile){const txt=await jsonFile.text();const obj=JSON.parse(txt);convs=Array.isArray(obj)?obj:(obj.conversations||[])}
if(htmlFile){htmlText=await htmlFile.text()}
let target=null;if(messages&&messages.length){target={title:document.title||"Conversa atual",messages:messages.map((m,i)=>({idx:i+1,role:m.role,parts:m.content?.parts||[]}))}}
else{const q=(titleLike||"").toLowerCase();for(const c of convs){const t=(c.title||"").toLowerCase();if(t.includes(q)){target=c;break}}if(!target&&convs.length===1)target=convs[0]}
if(!target)throw new Error("Conversa não encontrada. Informe parte do título.");
let ordered=[];if(target.mapping){const nodes=Object.values(target.mapping||{}).filter(x=>x&&typeof x==='object');const idToNode=Object.fromEntries(nodes.map(n=>[n.id,n]));const roots=nodes.filter(n=>!n.parent);
const vis=new Set();function dfs(n){if(!n||vis.has(n.id))return;vis.add(n.id);if(n.message&&n.message.content!=null)ordered.push(n);(n.children||[]).forEach(cid=>dfs(idToNode[cid]))}roots.forEach(dfs);if(!ordered.length)ordered=nodes.filter(n=>n.message)}
else if(target.messages){ordered=target.messages.map(m=>({message:{author:{role:m.role||'unknown'},content:{parts:m.parts||[]}}}))}
const files=[];const title=target.title||"conversa";const safe=title.replace(/[\\/*?:"<>|]/g,"_").slice(0,200);const md=[];md.push(`# ${title}`);md.push("");md.push("## INÍCIO");
let msgIdx=0;for(const node of ordered){const msg=node.message||{};const role=msg.author?.role||"unknown";const parts=Array.isArray(msg.content?.parts)?msg.content.parts:(Array.isArray(node.parts)?node.parts:[]);
const text=parts.filter(x=>typeof x==='string').join("\n\n");msgIdx++;md.push("---");const label=role==="user"?"✅iarate:":(role==="assistant"?"✅Aelly:":role);md.push(`**${msgIdx}. ${label}**  `);md.push(splitFences(text,msgIdx,files))}
md.push("");md.push("## MEIO");md.push("- (Notas e checkpoints.)");md.push("");md.push("## FIM");md.push("- (Conclusões e próximos passos.)");
const ps=files.filter(f=>f.name.endsWith(".ps1")).map(f=>f.data);const py=files.filter(f=>f.name.endsWith(".py")).map(f=>f.data);
if(ps.length)files.push({name:"CONVERSATIONCOMPILED.ps1",data:ps.join("\n\n# ---- bloco ----\n\n")});if(py.length)files.push({name:"CONVERSATIONCOMPILED.py",data:py.join("\n\n# ---- bloco ----\n\n")});
const html=`<!DOCTYPE html><html><head><meta charset="utf-8"><style>body{font-family:Segoe UI,Arial;background:#0b1220;color:#e5e9f0;margin:20px}.card{background:#111827;border:1px solid #1f2937;border-radius:12px;padding:16px;margin:12px 0}pre{background:#0a0f1a;border:1px solid #1f2937;border-radius:8px;padding:12px;overflow:auto;color:#d1d5db}.badge{padding:4px 8px;border-radius:8px;font-size:12px}.u{background:#1dd1a1;color:#06141f}.a{background:#54a0ff;color:#04101c}</style></head><body><h1>📁 ${safe}</h1><div>Legenda: <span class="badge u">✅iarate</span> <span class="badge a">✅Aelly</span></div><div class="card"><h2>📜 Histórico</h2><pre>${md.join("\n").replace(/[&<>]/g, s=>({"&":"&amp;","<":"&lt;",">":"&gt;"}[s]))}</pre></div></body></html>`;
files.unshift({name:`${safe}.md`,data:md.join("\n")});files.push({name:"index.html",data:html});
const blob=buildZipStore(files);const url=URL.createObjectURL(blob);chrome.downloads.download({url,filename:`${safe}_EXTRACAO.zip`,saveAs:true})}
window.CONVERSATIONS_GPT={processData};