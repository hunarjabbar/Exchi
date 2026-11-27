export type Audience = 'public'|'retailer'|'supplier'|'field'|'driver'|'command';
export type Context = {tenant_id:string;membership_id:string;scope_id:string|null;audience:Audience};
export class Fault extends Error { status:number; code:string; constructor(status:number, code:string){super(code);this.status=status;this.code=code;} }
export const AUDIENCES: readonly Audience[]=['public','retailer','supplier','field','driver','command'];
export function audience(v:unknown):Audience {if(typeof v!=='string'||!AUDIENCES.includes(v as Audience))throw new Fault(400,'INVALID_AUDIENCE');return v as Audience;}
export function uuid(v:unknown):string {if(typeof v!=='string'||!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(v))throw new Fault(400,'INVALID_ID');return v;}
export function revision(v:unknown):number {if(typeof v!=='number'||!Number.isSafeInteger(v)||v<1||v>2147483646)throw new Fault(400,'REVISION_REQUIRED');return v;}
export function normalize(s:string):string {return s.normalize('NFKC').toLowerCase().replace(/[٠-٩۰-۹]/g,d=>String(d.charCodeAt(0)-(d.charCodeAt(0)>=1776?1776:1632))).replace(/[ًٌٍَُِّْـ]/g,'').replace(/[أإآ]/g,'ا').replace(/ك/g,'ک').replace(/ي/g,'ی').trim();}
export function bearer(header:unknown):string {if(typeof header!=='string'||!/^Bearer [A-Za-z0-9_-]{43,128}$/.test(header))throw new Fault(401,'SESSION_REQUIRED');return header.slice(7);}
export const executionGates=Object.freeze({digitalPayment:false,tradeCredit:false,financialPosting:false,payout:false,authorizedFx:false,orderAcceptance:false,regulatedGoods:false});
export function requireCommand(a:Audience):void{if(a!=='command')throw new Fault(403,'COMMAND_ONLY');}
export const masters={
 'catalog.brand':{fields:['code','name_en','name_ar','name_ku'],required:['code','name_en']},
 'catalog.category':{fields:['code','name_en','name_ar','name_ku'],required:['code','name_en','name_ar','name_ku']},
 'catalog.product':{fields:['sku','category_id','brand_id','name_en','name_ar','name_ku'],required:['sku','category_id','name_en','name_ar','name_ku']}
} as const;
export type Master=keyof typeof masters;
export function master(v:unknown):Master{if(typeof v!=='string'||!Object.hasOwn(masters,v))throw new Fault(403,'PROTECTED_RESOURCE');return v as Master;}
export function fields(resource:Master,data:unknown,create:boolean):Record<string,string|null>{
 if(!data||typeof data!=='object'||Array.isArray(data))throw new Fault(400,'INVALID_PAYLOAD');
 const spec=masters[resource]; const out:Record<string,string|null>={};
 for(const [k,v] of Object.entries(data)){if(!(spec.fields as readonly string[]).includes(k))throw new Fault(400,'FIELD_NOT_ALLOWED');
 if(v===null&&(k==='brand_id'||(resource==='catalog.brand'&&['name_ar','name_ku'].includes(k)))){out[k]=null;continue;}
 if(typeof v!=='string'||!v.trim()||v.length>200)throw new Fault(400,'INVALID_FIELD');out[k]=k.endsWith('_id')?uuid(v):v.trim();}
 if(!Object.keys(out).length||(create&&spec.required.some(k=>!out[k])))throw new Fault(400,'MISSING_FIELDS');return out;
}
export type DraftLine={sku:string;cartons:number};
export function validateDraft(value:unknown):DraftLine[]{if(!Array.isArray(value)||value.length<1||value.length>250)throw new Fault(400,'INVALID_DRAFT');const seen=new Set<string>();return value.map(l=>{if(!l||typeof l!=='object'||Object.keys(l).some(k=>!['sku','cartons'].includes(k))||typeof l.sku!=='string'||!/^[\p{L}\p{N}_.-]{1,80}$/u.test(l.sku)||!Number.isSafeInteger(l.cartons)||l.cartons<1||l.cartons>100000||seen.has(normalize(l.sku)))throw new Fault(400,'INVALID_DRAFT_LINE');seen.add(normalize(l.sku));return {sku:l.sku,cartons:l.cartons};});}
export function estimateBonus(q:bigint, buy:bigint, free:bigint, unit:bigint, depositBps:bigint){if(q<=0n||buy<=0n||free<0n||unit<0n||depositBps<0n||depositBps>10000n)throw new Fault(400,'INVALID_ESTIMATE');const total=q*unit,bonus=q/buy*free,deposit=(total*depositBps+5000n)/10000n;return {total,bonus,shipped:q+bonus,deposit,cod:total-deposit};}
export function parseBulkDraft(text:unknown):DraftLine[]{if(typeof text!=='string'||text.length>65536)throw new Fault(400,'INVALID_DRAFT');const rows=text.split(/\r?\n/).filter(l=>l.trim()).map(l=>{const parts=l.split(/[\t,،;]/);if(parts.length!==2)throw new Fault(400,'INVALID_DRAFT_LINE');const raw=normalize(parts[1]);if(!/^[1-9][0-9]{0,5}$/.test(raw))throw new Fault(400,'INVALID_DRAFT_LINE');return {sku:parts[0].trim(),cartons:Number(raw)}});return validateDraft(rows);}
