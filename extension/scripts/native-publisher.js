/* Disponível somente nas páginas internas; nunca encaminha comandos de sites. */
class NativePublisher {
  constructor(){this.port=null;this.pending=new Map();this.sequence=0;}
  async open(){
    if(this.port)return;
    const granted=await chrome.permissions.request({permissions:['nativeMessaging']});
    if(!granted)throw new Error('Permissão do host recusada. As ferramentas locais continuam disponíveis.');
    this.port=chrome.runtime.connectNative('com.izgith.host');
    this.port.onMessage.addListener(response=>{const entry=this.pending.get(response.requestId);if(!entry)return;this.pending.delete(response.requestId);clearTimeout(entry.timer);response.ok||response.cancelled?entry.resolve(response):entry.reject(new Error(response.error||'Falha no host.'));});
    this.port.onDisconnect.addListener(()=>{const error=new Error(chrome.runtime.lastError?.message||'Host desconectado. Instale o host e registre o ID da extensão.');this.port=null;for(const p of this.pending.values()){clearTimeout(p.timer);p.reject(error);}this.pending.clear();});
  }
  call(command,data={}){
    if(!this.port)return Promise.reject(new Error('Conecte o host antes de selecionar arquivos.'));
    return new Promise((resolve,reject)=>{const requestId=++this.sequence;const timer=setTimeout(()=>{this.pending.delete(requestId);reject(new Error('A operação demorou mais que o esperado. Confira o GitHub antes de repetir.'));},35*60*1000);this.pending.set(requestId,{resolve,reject,timer});this.port.postMessage({...data,command,requestId});});
  }
  close(){if(this.port)this.port.disconnect();}
}
globalThis.NativePublisher=NativePublisher;
