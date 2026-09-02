export function normalizeChatRecord(record={}){return {id:String(record.id||crypto.randomUUID()),title:String(record.title||'Conversa'),updatedAt:String(record.updatedAt||new Date().toISOString())};}
