import {cookies} from 'next/headers';
import type {Audience} from '../core/index.ts';
const json=(body:unknown,status=200)=>Response.json(body,{status,headers:{'cache-control':'no-store'}});
export function enterpriseProxy(audience:Audience){return async function proxy(req:Request,{params}:{params:Promise<{segments:string[]}>}){
 const path=(await params).segments.join('/');
 if(!/^(session|workspace|retailer\/(catalog|entitlement)|auth\/(otp\/(request|verify)|logout)|sync\/drafts|masters\/catalog\.(brand|category|product)(\/[0-9a-f-]{36}(\/archive)?)?)$/.test(path))return json({code:'NOT_FOUND'},404);
 if(audience==='public')return json({code:'PUBLIC_SESSION_DENIED'},403);
 const mutation=req.method!=='GET';if(mutation&&(!process.env.APP_ORIGIN||req.headers.get('origin')!==process.env.APP_ORIGIN))return json({code:'ORIGIN_DENIED'},403);
 const anon=path==='auth/otp/request'||path==='auth/otp/verify';if(anon&&req.method!=='POST')return json({code:'METHOD_DENIED'},405);
 if(path.startsWith('retailer/')&&audience!=='retailer'||path.startsWith('masters/')&&audience!=='command'||path==='sync/drafts'&&audience!=='retailer')return json({code:'AUDIENCE_DENIED'},403);
 const jar=await cookies(),name='__Host-wholesale-session-'+audience,token=jar.get(name)?.value;
 if(!anon&&!token)return json({code:'SESSION_REQUIRED'},401);
 const base=process.env.ENTERPRISE_API_URL;if(!base)return json({code:'API_NOT_CONFIGURED'},503);
 try{const u=new URL('/v1/'+path,base);u.search=new URL(req.url).search;
 const headers:Record<string,string>={'x-app-audience':audience,'content-type':'application/json'};if(token&&!anon)headers.authorization='Bearer '+token;
 const body=mutation?await req.text():undefined;if(body&&body.length>100000)return json({code:'PAYLOAD_TOO_LARGE'},413);
 const r=await fetch(u,{method:req.method,headers,body,cache:'no-store',redirect:'error',signal:AbortSignal.timeout(18000)});
 if(path==='auth/otp/request'&&r.ok){const data=await r.json();if(data.channel==='DEV'&&!(process.env.ALLOW_DEV_OTP_PROXY==='YES'&&/^http:\/\/localhost:\d+$/.test(process.env.APP_ORIGIN??'')))return json({code:'DEV_OTP_PROXY_DENIED'},503);return json(data);}
 if(path==='auth/otp/verify'&&r.ok){const data=await r.json();if(typeof data.token!=='string'||! /^[A-Za-z0-9_-]{43}$/.test(data.token)||data.expiresIn!==(audience==='retailer'?86400:28800))return json({code:'INVALID_SESSION_RESPONSE'},502);jar.set(name,data.token,{httpOnly:true,secure:true,sameSite:'strict',path:'/',maxAge:data.expiresIn});return json({authenticated:true,expiresIn:data.expiresIn});}
 if(path==='auth/logout'&&r.ok){jar.set(name,'',{httpOnly:true,secure:true,sameSite:'strict',path:'/',maxAge:0});return json({revoked:true});}
 if(path==='session'&&r.status===401)jar.set(name,'',{httpOnly:true,secure:true,sameSite:'strict',path:'/',maxAge:0});
 return new Response(r.body,{status:r.status,headers:{'content-type':'application/json','cache-control':'no-store'}});
 }catch{return json({code:'API_UNAVAILABLE'},503);}
};}
