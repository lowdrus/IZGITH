const {test}=require('node:test');
const assert=require('node:assert/strict');
const vm=require('node:vm');
const fs=require('node:fs');
const path=require('node:path');
const root=path.join(__dirname,'../extension');
function context(){
  const handlers=[], local={}, session={}, tabs=[];
  const event=()=>({addListener(){}});
  const storage=bag=>({get:async key=>typeof key==='string'?{[key]:bag[key]}:key===null?{...bag}:{...key,...bag},set:async patch=>Object.assign(bag,patch),remove:async key=>{delete bag[key]}});
  const chrome={runtime:{id:'test',onMessage:{addListener:fn=>handlers.push(fn)},onInstalled:event(),onStartup:event(),getURL:p=>'chrome-extension://test/'+p,getManifest:()=>({version:'6.0.0.65'}),getContexts:async()=>[],sendMessage:(_m,cb)=>{if(cb)cb({ok:true});return Promise.resolve({ok:true})}},storage:{local:storage(local),session:storage(session),onChanged:event()},tabs:{onRemoved:event(),onUpdated:event(),create:async options=>{tabs.push(options);return{id:1}},sendMessage:async()=>({}),query:(_q,cb)=>cb?.([])},alarms:{create(){},onAlarm:event()},commands:{onCommand:event()},contextMenus:{removeAll:cb=>cb?.(),create(){},onClicked:event()},declarativeNetRequest:{updateDynamicRules:async()=>{},updateSessionRules:async()=>{}},webRequest:{onBeforeRequest:event()},action:{setBadgeText(){},setBadgeBackgroundColor(){}},offscreen:{createDocument:async()=>{}},scripting:{executeScript:async()=>{}}};
  const errors=[];const ctx=vm.createContext({chrome,URL,TextEncoder,crypto:require('node:crypto').webcrypto,console:{log(){},warn(){},error:e=>errors.push(e)},setTimeout,clearTimeout,fetch:async()=>({ok:false})});
  return {ctx,handlers,local,session,tabs,errors};
}
test('worker JDOWNLOADER inicia e recusa operações privilegiadas de sites',async()=>{
  const c=context();vm.runInContext(fs.readFileSync(path.join(root,'modules/jdownloader/background.js'),'utf8'),c.ctx);
  await new Promise(resolve=>setImmediate(resolve));assert.deepEqual(c.errors,[]);
  const handler=c.handlers[0];assert.equal(handler({action:'login',data:{}},{id:'test',tab:{id:1},url:'https://example.com'},()=>{}),false);
  let response;handler({action:'captcha-solved',data:{callbackUrl:'https://example.com/?x=1'}},{id:'test',tab:{id:1},url:'https://example.com'},r=>response=r);
  assert.equal(response.error,'Callback não autorizado.');
});
test('FORSE exige origem e configuração exatas, sem publicar automaticamente',async()=>{
  const c=context();vm.runInContext(fs.readFileSync(path.join(root,'scripts/forse-worker.js'),'utf8'),c.ctx);
  const invoke=(m,s)=>new Promise(resolve=>c.handlers[0](m,s,resolve));
  let response=await invoke({type:'FORSE_PREVIEW'},{id:'evil'});assert.equal(response.ok,false);
  c.local.forseConfig={enabled:true,conversation:'https://chatgpt.com/c/test',repository:'https://github.com/a/b'};
  const message={type:'FORSE_PREVIEW',payload:{schema:'izgith.forse-sinc.v1',conversation:c.local.forseConfig.conversation,messages:[{role:'user',text:'Teste público'}]}};
  response=await invoke(message,{id:'test',tab:{id:5},frameId:0,url:'https://chatgpt.com/c/test'});
  assert.equal(response.ok,true);assert.equal(c.tabs.length,1);assert.match(c.tabs[0].url,/ui\/publish.html#forse_/);
  response=await invoke(message,{id:'test',tab:{id:5},frameId:0,url:'https://chatgpt.com/c/test'});assert.equal(response.ok,false);
  assert.equal(Object.keys(c.session).length,1);
});
