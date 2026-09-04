const {test}=require('node:test');const assert=require('node:assert/strict');const vm=require('node:vm');const fs=require('node:fs');const path=require('node:path');
function fixture(mode){
  let receive,disconnect;let connects=0;
  const port={onMessage:{addListener:fn=>receive=fn},onDisconnect:{addListener:fn=>disconnect=fn},postMessage(message){if(mode==='throw')throw Error('Porta fechada');queueMicrotask(()=>{if(mode==='disconnect'){disconnect();return;}receive({ok:true,host:'com.izgith.host',publisher_protocol:mode==='old'?0:1,requestId:message.requestId});});},disconnect(){disconnect?.();}};
  const context=vm.createContext({chrome:{permissions:{request:async()=>mode!=='denied'},runtime:{connectNative(){connects++;return port;}}},setTimeout,clearTimeout,Error});
  vm.runInContext(fs.readFileSync(path.join(__dirname,'../extension/scripts/native-publisher.js'),'utf8'),context);
  return {client:new context.NativePublisher(),connects:()=>connects};
}
test('handshake real do cliente evita conexões duplicadas',async()=>{const f=fixture('ok');await Promise.all([f.client.open(),f.client.open()]);assert.equal(f.connects(),1);assert.equal(f.client.ready,true);f.client.close();assert.equal(f.client.ready,false);});
test('permissão recusada, host antigo, desconexão e postMessage inválido não dão sucesso',async()=>{for(const mode of ['denied','old','disconnect','throw']){const f=fixture(mode);await assert.rejects(f.client.open());assert.equal(f.client.ready,false);assert.equal(f.client.pending.size,0);}});
