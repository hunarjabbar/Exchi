import {createHmac,randomInt,randomBytes,timingSafeEqual,createHash} from 'node:crypto';
import {Fault,audience,uuid,type Audience} from './index.ts';
export type LoginAudience=Exclude<Audience,'public'>;
export function loginAudience(v:unknown):LoginAudience {const a=audience(v);if(a==='public')throw new Fault(403,'PUBLIC_LOGIN_DENIED');return a;}
export function phoneNumber(v:unknown):string {if(typeof v!=='string'||v.length>40)throw new Fault(400,'INVALID_PHONE');let s=v.replace(/[٠-٩۰-۹]/g,d=>String(d.charCodeAt(0)-(d.charCodeAt(0)>=1776?1776:1632))).replace(/[\s()-]/g,'');if(s.startsWith('00964'))s='+'+s.slice(2);if(/^07\d{9}$/.test(s))s='+964'+s.slice(1);if(!/^\+9647\d{9}$/.test(s))throw new Fault(400,'INVALID_PHONE');return s;}
export function tenantCode(v:unknown):string{if(typeof v!=='string'||!/^[-_A-Za-z0-9]{1,64}$/.test(v))throw new Fault(400,'INVALID_TENANT');return v;}
export function otpCode(v:unknown):string {if(typeof v!=='string')throw new Fault(400,'INVALID_CODE');const s=v.replace(/[٠-٩۰-۹]/g,d=>String(d.charCodeAt(0)-(d.charCodeAt(0)>=1776?1776:1632))).trim();if(!/^\d{6}$/.test(s))throw new Fault(400,'INVALID_CODE');return s;}
export function newOtp(){return String(randomInt(0,1000000)).padStart(6,'0');}
export function newToken(){return randomBytes(32).toString('base64url');}
export const tokenDigest=(v:string)=>createHash('sha256').update(v).digest('hex');
export function otpDigest(key:string,id:string,phone:string,tenant:string,app:LoginAudience,code:string){if(!/^[0-9a-f]{64}$/i.test(key))throw new Fault(503,'AUTH_CONFIGURATION_REQUIRED');return createHmac('sha256',Buffer.from(key,'hex')).update(JSON.stringify([uuid(id),phone,tenant,app,code])).digest('hex');}
// RFC 6238: six digits, SHA-1, 30s. Secrets are 20-byte hex values, provided by a private secrets manager.
export function totpAt(secret:string,step:number):string {if(!/^[0-9a-f]{40}$/i.test(secret)||!Number.isSafeInteger(step)||step<0)throw new Error('invalid TOTP material');const b=Buffer.alloc(8);b.writeBigUInt64BE(BigInt(step));const h=createHmac('sha1',Buffer.from(secret,'hex')).update(b).digest();const o=h[h.length-1]&15;return String((h.readUInt32BE(o)&0x7fffffff)%1000000).padStart(6,'0');}
export function verifyTotp(secret:string|undefined,code:unknown,now=Date.now()):number|null{if(!secret||!(/^[0-9a-f]{40}$/i.test(secret)))return null;let c:string;try{c=otpCode(code)}catch{return null}const step=Math.floor(now/30000);for(const delta of [0,-1,1]){const candidate=step+delta;if(candidate>=0&&timingSafeEqual(Buffer.from(totpAt(secret,candidate)),Buffer.from(c)))return candidate;}return null;}
export function devOtpAllowed(env:NodeJS.ProcessEnv,phone:string,tenant:string){return env.AUTH_MODE==='dev'&&env.NODE_ENV!=='production'&&env.ALLOW_LOCAL_DEV_OTP==='YES'&&tenant==='wholesale-local'&&/^\+96475000000\d{2}$/.test(phone);}
