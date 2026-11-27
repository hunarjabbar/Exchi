import { z } from 'zod';
const secret=z.string().min(32).refine(v=>!/(replace|example|change.?me|placeholder)/i.test(v),'Invalid secret');
const url=z.string().url();
const db=z.string().url().refine(v=>/^postgres(?:ql)?:\/\//.test(v),'PostgreSQL URL required');
const schema=z.object({
 RELEASE_ENV:z.enum(['local','staging','production']).default('local'),
 RUNTIME_DATABASE_URL:db,
 PORT:z.coerce.number().int().min(1).max(65535).default(4000),
 AUTH_MODE:z.enum(['disabled','dev','live']).default('disabled'),
 AUTH_LIVE_APPROVED:z.enum(['YES','NO']).default('NO'),
 ALLOW_LOCAL_DEV_OTP:z.enum(['YES','NO']).default('NO'),
 AUTH_OTP_HMAC_KEY:z.string().regex(/^[a-f0-9]{64}$/i).optional(),
 AUTH_RETAILER_SIGNUP_TENANT:z.string().min(1).optional(),
 AUTH_STAFF_TOTP_JSON:z.string().optional(),
 REDIS_URL:z.string().url().refine(v=>/^rediss?:\/\//.test(v)).optional(),
 JWT_ACCESS_SECRET:secret.optional(),JWT_REFRESH_SECRET:secret.optional(),
 S3_ENDPOINT:url.optional(),S3_BUCKET:z.string().min(3).optional(),S3_REGION:z.string().min(1).optional(),S3_ACCESS_KEY_ID:z.string().min(1).optional(),S3_SECRET_ACCESS_KEY:secret.optional(),
 ZAINCASH_CLIENT_ID:z.string().min(1).optional(),ZAINCASH_CLIENT_SECRET:secret.optional(),
 FIB_CLIENT_ID:z.string().min(1).optional(),FIB_CLIENT_SECRET:secret.optional(),
 FASTPAY_STORE_ID:z.string().min(1).optional(),FASTPAY_STORE_PASSWORD:z.string().min(1).optional(),
 FINANCIAL_EXECUTION:z.literal('LOCKED').default('LOCKED'),
});
const external=['REDIS_URL','JWT_ACCESS_SECRET','JWT_REFRESH_SECRET','S3_ENDPOINT','S3_BUCKET','S3_REGION','S3_ACCESS_KEY_ID','S3_SECRET_ACCESS_KEY','ZAINCASH_CLIENT_ID','ZAINCASH_CLIENT_SECRET','FIB_CLIENT_ID','FIB_CLIENT_SECRET','FASTPAY_STORE_ID','FASTPAY_STORE_PASSWORD'] as const;
export function validateRuntimeEnv(env:NodeJS.ProcessEnv){
 const input=Object.fromEntries(Object.entries(env).filter(([,v])=>v!==''));
 const parsed=schema.safeParse(input);
 if(!parsed.success)throw new Error('Invalid runtime configuration: '+parsed.error.issues.map(i=>i.path.join('.')).join(', '));
 const e=parsed.data;
 const errors:string[]=[];
 if(e.RELEASE_ENV==='local'){
  if(env.NODE_ENV==='production')errors.push('explicit staging or production RELEASE_ENV required');
  if(e.AUTH_MODE==='live'||e.AUTH_LIVE_APPROVED==='YES')errors.push('local live authentication forbidden');
  if(e.AUTH_MODE==='dev'&&(e.ALLOW_LOCAL_DEV_OTP!=='YES'||!e.AUTH_OTP_HMAC_KEY||!e.AUTH_RETAILER_SIGNUP_TENANT||!e.AUTH_STAFF_TOTP_JSON||!/^postgresql:\/\/wholesale_stepab_login:[^@]+@127\.0\.0\.1:55432\/wholesale_test$/.test(e.RUNTIME_DATABASE_URL)))errors.push('invalid isolated dev configuration');
 } else {
  for(const k of external)if(!e[k]||/(replace_with|change.?me|placeholder|example\.invalid)/i.test(e[k]??''))errors.push(k);
  if(e.AUTH_MODE!=='disabled'||e.AUTH_LIVE_APPROVED!=='NO'||e.ALLOW_LOCAL_DEV_OTP!=='NO')errors.push('Gate 1 requires external authentication disabled');
  if(e.JWT_ACCESS_SECRET===e.JWT_REFRESH_SECRET)errors.push('JWT secrets must differ');
  if(e.RELEASE_ENV==='production'&&!e.REDIS_URL?.startsWith('rediss://'))errors.push('production Redis TLS required');
  if(!e.S3_ENDPOINT?.startsWith('https://'))errors.push('S3 TLS required');
 }
 if(e.AUTH_STAFF_TOTP_JSON)try{const v:unknown=JSON.parse(e.AUTH_STAFF_TOTP_JSON);if(!v||typeof v!=='object'||Array.isArray(v)||Object.entries(v).some(([k,s])=>!/^\+9647\d{9}$/.test(k)||typeof s!=='string'||!(/^[a-f0-9]{40}$/i.test(s))))errors.push('AUTH_STAFF_TOTP_JSON');}catch{errors.push('AUTH_STAFF_TOTP_JSON');}
 const u=new URL(e.RUNTIME_DATABASE_URL);if(['postgres','root'].includes(decodeURIComponent(u.username))||!u.username||!u.password)errors.push('restricted runtime DB credentials required');
 if(errors.length)throw new Error('Invalid runtime configuration: '+errors.join(', '));
 return e;
}
