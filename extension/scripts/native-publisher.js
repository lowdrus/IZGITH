/* Disponível somente nas páginas internas; nunca encaminha comandos de sites. */
class NativePublisher {
  constructor(){this.port=null;this.pending=new Map();this.sequence=0;this.connecting=null;this.ready=false;}
  open(){
    if(this.ready)return Promise.resolve();
    if(this.connecting)return this.connecting;
    this.connecting=this.connect().finally(()=>{this.connecting=null;});
    return this.connecting;
  }
  async connect(){
    const granted=await chrome.permissions.request({permissions:['nativeMessaging']});
    if(!granted)throw new Error('Permissão do host recusada. As ferramentas locais continuam disponíveis.');
    const port=chrome.runtime.connectNative('com.izgith.host');this.port=port;
    port.onMessage.addListener(response=>{if(this.port!==port||!response)return;const entry=this.pending.get(response.requestId);if(!entry)return;this.pending.delete(response.requestId);clearTimeout(entry.timer);response.ok||response.cancelled?entry.resolve(response):entry.reject(new Error(response.error||'Falha no host.'));});
    port.onDisconnect.addListener(()=>{const detail=chrome.runtime.lastError?.message;if(this.port!==port)return;this.fail(new Error(detail||'Host desconectado. Execute o instalador e confira o ID da extensão.'));});
    try{
      const hello=await this.call('ping',{},30000);
      if(hello.host!=='com.izgith.host'||hello.publisher_protocol!==1)throw new Error('Host antigo ou incompatível. Execute o instalador atualizado.');
      this.ready=true;
    }catch(error){this.close();throw error;}
  }
  call(command,data={},timeout=35*60*1000){
    if(!this.port)return Promise.reject(new Error('Conecte o host antes de selecionar arquivos.'));
    return new Promise((resolve,reject)=>{const requestId=++this.sequence;const timer=setTimeout(()=>{this.pending.delete(requestId);reject(new Error('A operação demorou mais que o esperado. Confira o GitHub antes de repetir.'));},timeout);this.pending.set(requestId,{resolve,reject,timer});try{this.port.postMessage({...data,command,requestId});}catch(error){clearTimeout(timer);this.pending.delete(requestId);reject(error);}});
  }
  fail(error){
    this.port=null;this.ready=false;for(const p of this.pending.values()){clearTimeout(p.timer);p.reject(error);}this.pending.clear();
  }
  close(){const port=this.port;this.fail(new Error('Conexão encerrada. Confira o GitHub se havia envio em andamento.'));if(port)port.disconnect();}
}
globalThis.NativePublisher=NativePublisher;
