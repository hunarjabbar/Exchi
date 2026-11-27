import {Fault} from '../../../packages/core/index.ts';
export type Channel='WHATSAPP'|'SMS';
function required(k:string){const v=process.env[k];if(!v)throw new Fault(503,'AUTH_PROVIDER_CONFIGURATION_REQUIRED');return v;}
async function send(url:string,init:RequestInit){const r=await fetch(url,{...init,redirect:'error',signal:AbortSignal.timeout(8000)});if(!r.ok)throw new Fault(503,'OTP_PROVIDER_REJECTED');const data:unknown=await r.json();return data;}
export async function deliverOtp(phone:string,code:string,channel:Channel){
 if(channel==='WHATSAPP'){
  const version=required('META_GRAPH_VERSION'),id=required('META_PHONE_NUMBER_ID');if(!/^v\d+\.\d+$/.test(version)||!/^\d+$/.test(id))throw new Fault(503,'AUTH_PROVIDER_CONFIGURATION_REQUIRED');
  const data=await send(`https://graph.facebook.com/${version}/${id}/messages`,{method:'POST',headers:{authorization:'Bearer '+required('META_ACCESS_TOKEN'),'content-type':'application/json'},body:JSON.stringify({messaging_product:'whatsapp',to:phone.slice(1),type:'template',template:{name:required('META_AUTH_TEMPLATE'),language:{code:required('META_AUTH_LANGUAGE')},components:[{type:'body',parameters:[{type:'text',text:code}]},{type:'button',sub_type:'url',index:'0',parameters:[{type:'text',text:code}]}]}})});
  if(!(data as {messages?:{id?:string}[]})?.messages?.[0]?.id)throw new Fault(503,'OTP_PROVIDER_UNCONFIRMED');
 }else{
  const sid=required('TWILIO_ACCOUNT_SID');if(!/^AC[0-9a-f]{32}$/i.test(sid))throw new Fault(503,'AUTH_PROVIDER_CONFIGURATION_REQUIRED');
  const data=await send(`https://api.twilio.com/2010-04-01/Accounts/${sid}/Messages.json`,{method:'POST',headers:{authorization:'Basic '+Buffer.from(sid+':'+required('TWILIO_AUTH_TOKEN')).toString('base64'),'content-type':'application/x-www-form-urlencoded'},body:new URLSearchParams({To:phone,From:required('TWILIO_FROM'),Body:`Wholesale. verification code: ${code}. Expires in 5 minutes. Do not share.`})});
  if(!(data as {sid?:string})?.sid)throw new Fault(503,'OTP_PROVIDER_UNCONFIRMED');
 }
}
/**
 * WhatsApp-first delivery with an explicitly consented, operator-enabled SMS fallback.
 * Provider failures never silently switch channels: both policy and customer consent are required.
 */
export async function deliverOtpWithFallback(phone:string,code:string,primary:Channel,allowSmsFallback:boolean):Promise<Channel>{
 try{await deliverOtp(phone,code,primary);return primary;}
 catch(error){
  if(primary!=='WHATSAPP'||!allowSmsFallback)throw error;
  await deliverOtp(phone,code,'SMS');
  return 'SMS';
 }
}
