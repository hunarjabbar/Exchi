import 'reflect-metadata';
import {validateRuntimeEnv} from './runtime-env.ts';
import {Controller, Module, Get, Post, Patch, Delete, Body, Param, Headers, Query, HttpException, Injectable, HttpCode} from '@nestjs/common';
import {NestFactory} from '@nestjs/core';
import {Pool, type PoolClient} from 'pg';
import {createHash,randomUUID} from 'node:crypto';
import {readFileSync} from 'node:fs';
import {audience,bearer,master,masters,fields,revision,uuid,requireCommand,validateDraft,executionGates,Fault,type Context,type Audience} from '../../../packages/core/index.ts';
import {loginAudience,phoneNumber,tenantCode,otpCode,newOtp,newToken,tokenDigest,otpDigest,verifyTotp,devOtpAllowed} from '../../../packages/core/auth.ts';
import {deliverOtpWithFallback,type Channel} from './auth-delivery.ts';
const routes=JSON.parse(readFileSync(process.env.ROUTE_REGISTRY_PATH??'../../packages/contracts/routes.json','utf8')) as {role:Audience;path:string;resource:string;readColumns:string[]}[];
const ident=(s:string)=>'"'+s.replace(/"/g,'""')+'"';
const table=(s:string)=>s.split('.').map(ident).join('.');
// Use the pre-existing runtime-granted permission predicate; RLS remains independently enforced.
async function requireRuntimePermission(db:PoolClient,c:Context,permission:string):Promise<void>{const result=await db.query<{allowed:boolean}>('SELECT app_private.can($1,$2,$3) AS allowed',[c.tenant_id,c.scope_id,permission]);if(result.rows[0]?.allowed!==true)throw new Fault(403,'ACCESS_DENIED');}
const safeError=(e:unknown):never=>{if(e instanceof HttpException)throw e;if(e instanceof Fault)throw new HttpException({code:e.code},e.status);const code=(e as {code?:string})?.code;if(code==='42501')throw new HttpException({code:'ACCESS_DENIED'},403);if(code==='23505')throw new HttpException({code:'CONFLICT'},409);if(['23503','23514','22P02','22023'].includes(code??''))throw new HttpException({code:'INVALID_REFERENCE_OR_VALUE'},422);throw new HttpException({code:'SERVICE_UNAVAILABLE'},503);};
@Injectable()
class Db {
 private pool=new Pool({connectionString:process.env.RUNTIME_DATABASE_URL,max:10,statement_timeout:5000});
 async auth<T>(fn:(db:PoolClient)=>Promise<T>):Promise<T>{let db:PoolClient|undefined;try{if(!process.env.RUNTIME_DATABASE_URL)throw new Fault(503,'DATABASE_NOT_CONFIGURED');db=await this.pool.connect();await db.query('BEGIN');await db.query('SET LOCAL ROLE wholesale_runtime');const result=await fn(db);await db.query('COMMIT');return result;}catch(e){if(db)await db.query('ROLLBACK').catch(()=>{});return safeError(e);}finally{db?.release();}}
 async run<T>(h:unknown,a:unknown,fn:(db:PoolClient,c:Context)=>Promise<T>):Promise<T>{let db:PoolClient|undefined;try{const token=bearer(h), app=audience(a);if(app==='public')throw new Fault(403,'PUBLIC_SESSION_DENIED');if(!process.env.RUNTIME_DATABASE_URL)throw new Fault(503,'DATABASE_NOT_CONFIGURED');db=await this.pool.connect();await db.query('BEGIN');await db.query('SET LOCAL ROLE wholesale_runtime');const res=await db.query<Context>('SELECT * FROM app_private.resolve_login($1,$2)',[createHash('sha256').update(token).digest('hex'),app]);const c=res.rows[0];if(!c)throw new Fault(401,'INVALID_SESSION');await db.query("SELECT set_config('app.tenant_id',$1,true),set_config('app.membership_id',$2,true),set_config('app.correlation_id',$3,true),set_config('app.audience',$4,true)",[c.tenant_id,c.membership_id,randomUUID(),app]);const result=await fn(db,c);await db.query('COMMIT');return result;}catch(e){if(db)await db.query('ROLLBACK').catch(()=>{});return safeError(e);}finally{db?.release();}}
}
@Controller('v1')
class Api {
 constructor(private db:Db){}
 @Get('health') health(){return {status:'process_alive',certification:'PENDING',executionGates};}
 @Get('ready') async ready(){return this.db.auth(async db=>{await db.query("SELECT 1 FROM app_private.resolve_login(repeat('0',64),'retailer')");return {status:'database_reachable',certification:'PENDING',executionGates};});}
 @Post('auth/otp/request') @HttpCode(200) async requestOtp(@Headers('x-app-audience') a:string,@Body() body:{phone:unknown;tenant:unknown;channel?:unknown;consent?:unknown;smsFallbackConsent?:unknown}){try{
 const app=loginAudience(a),phone=phoneNumber(body?.phone),tenant=tenantCode(body?.tenant);if(body?.consent!==true)throw new Fault(400,'CONSENT_REQUIRED');const channel:Channel=body?.channel==='SMS'?'SMS':'WHATSAPP';if(body?.channel!==undefined&&!['SMS','WHATSAPP'].includes(String(body.channel)))throw new Fault(400,'INVALID_CHANNEL');
 const dev=devOtpAllowed(process.env,phone,tenant);if(!dev&&!(process.env.AUTH_MODE==='live'&&process.env.AUTH_LIVE_APPROVED==='YES'))throw new Fault(503,'AUTH_MODE_DISABLED');
 const id=randomUUID(),code=newOtp(),hash=otpDigest(process.env.AUTH_OTP_HMAC_KEY??'',id,phone,tenant,app,code);
 const ok=await this.db.auth(async db=>(await db.query<{ok:boolean}>('SELECT app_private.begin_otp($1,$2,$3,$4,$5,$6) AS ok',[id,phone,tenant,app,hash,dev?'DEV':channel])).rows[0].ok);if(!ok)throw new Fault(429,'OTP_RATE_LIMIT');
 if(dev)return {challengeId:id,expiresIn:300,channel:'DEV',devCode:code};
 let deliveredChannel:Channel;
 try{deliveredChannel=await deliverOtpWithFallback(phone,code,channel,channel==='WHATSAPP'&&body?.smsFallbackConsent===true&&process.env.AUTH_SMS_FALLBACK_ENABLED==='YES');}catch(e){await this.db.auth(async db=>{await db.query('SELECT app_private.invalidate_otp($1)',[id]);});throw e;}
 if(deliveredChannel!==channel){
  try{
   const recorded=await this.db.auth(async db=>(await db.query<{ok:boolean}>('SELECT app_private.set_otp_delivery_channel($1,$2) AS ok',[id,deliveredChannel])).rows[0].ok);
   if(!recorded)throw new Fault(503,'OTP_DELIVERY_STATE_CONFLICT');
  }catch(e){
   await this.db.auth(async db=>{await db.query('SELECT app_private.invalidate_otp($1)',[id]);});
   throw e;
  }
 }
 return {challengeId:id,expiresIn:300,channel:deliveredChannel,fallbackUsed:deliveredChannel!==channel};
 }catch(e){return safeError(e);}}
 @Post('auth/otp/verify') @HttpCode(200) async verifyOtp(@Headers('x-app-audience') a:string,@Body() body:{phone:unknown;tenant:unknown;challengeId:unknown;code:unknown;mfaCode?:unknown}){try{
 const app=loginAudience(a),phone=phoneNumber(body?.phone),tenant=tenantCode(body?.tenant),id=uuid(body?.challengeId),code=otpCode(body?.code);
 if(!(process.env.AUTH_MODE==='live'&&process.env.AUTH_LIVE_APPROVED==='YES')&&!devOtpAllowed(process.env,phone,tenant))throw new Fault(503,'AUTH_MODE_DISABLED');
 const secrets=JSON.parse(process.env.AUTH_STAFF_TOTP_JSON??'{}') as Record<string,string>;const step=app==='retailer'?null:verifyTotp(Object.hasOwn(secrets,phone)?secrets[phone]:undefined,body?.mfaCode);const token=newToken();
 const digest=otpDigest(process.env.AUTH_OTP_HMAC_KEY??'',id,phone,tenant,app,code);
 const signup=app==='retailer'&&tenant===process.env.AUTH_RETAILER_SIGNUP_TENANT;
 const ok=await this.db.auth(async db=>(await db.query<{ok:boolean}>('SELECT app_private.finish_otp($1,$2,$3,$4,$5,$6,$7,$8) AS ok',[id,phone,tenant,app,digest,tokenDigest(token),step,signup])).rows[0].ok);
 if(!ok)throw new Fault(401,'VERIFICATION_FAILED');return {token,expiresIn:app==='retailer'?86400:28800};
 }catch(e){return safeError(e);}}
 @Post('auth/logout') @HttpCode(200) async logout(@Headers('authorization') h:string,@Headers('x-app-audience') a:string){try{const app=loginAudience(a),digest=tokenDigest(bearer(h));await this.db.auth(async db=>{await db.query('SELECT app_private.logout_login($1,$2)',[digest,app]);});return {revoked:true};}catch(e){return safeError(e);}}
 @Get('retailer/entitlement') entitlement(@Headers('authorization') h:string,@Headers('x-app-audience') a:string){return this.db.run(h,a,async(db,c)=>{if(c.audience!=='retailer'||!c.scope_id)throw new Fault(403,'RETAILER_REQUIRED');const r=await db.query('SELECT * FROM app_private.retail_entitlement($1,$2,$3)',[c.tenant_id,c.membership_id,c.scope_id]);if(!r.rowCount)throw new Fault(403,'RETAILER_REQUIRED');return r.rows[0];});}
 @Get('retailer/catalog') catalog(@Headers('authorization') h:string,@Headers('x-app-audience') a:string){return this.db.run(h,a,async(db,c)=>{if(c.audience!=='retailer'||!c.scope_id)throw new Fault(403,'RETAILER_REQUIRED');return (await db.query('SELECT app_private.retail_catalog($1,$2,$3) AS product',[c.tenant_id,c.membership_id,c.scope_id])).rows.map(r=>r.product);});}
 @Get('session') session(@Headers('authorization') h:string,@Headers('x-app-audience') a:string){return this.db.run(h,a,async(_db,c)=>c);}
 @Get('workspace') workspace(@Headers('authorization') h:string,@Headers('x-app-audience') a:string,@Query('path') path:string){return this.db.run(h,a,async(db,c)=>{const r=routes.find(x=>x.role===c.audience&&x.path===path);if(!r)throw new Fault(404,'ROUTE_NOT_FOUND');if(!r.readColumns.length)return {state:'NOT_IMPLEMENTED',rows:[]};await requireRuntimePermission(db,c,r.resource+'.read');const sql=`SELECT ${r.readColumns.map(ident).join(',')} FROM ${table(r.resource)} WHERE tenant_id=$1 AND ($2::uuid IS NULL OR scope_id=$2) AND archived_at IS NULL ORDER BY created_at DESC,id LIMIT 100`;return {state:'SCOPED_READ',rows:(await db.query(sql,[c.tenant_id,c.scope_id])).rows};});}
 @Get('masters/:resource') list(@Headers('authorization') h:string,@Headers('x-app-audience') a:string,@Param('resource') raw:string,@Query('archived') archived:string){return this.db.run(h,a,async(db,c)=>{requireCommand(c.audience);const r=master(raw);await requireRuntimePermission(db,c,r+'.read');return (await db.query(`SELECT id,version,archived_at,${masters[r].fields.map(ident).join(',')} FROM ${table(r)} WHERE tenant_id=$1 AND ($2::uuid IS NULL OR scope_id=$2) AND archived_at IS ${archived==='true'?'NOT ':''}NULL ORDER BY created_at DESC,id LIMIT 100`,[c.tenant_id,c.scope_id])).rows;});}
 @Post('masters/:resource') create(@Headers('authorization') h:string,@Headers('x-app-audience') a:string,@Param('resource') raw:string,@Body() data:unknown){return this.db.run(h,a,async(db,c)=>{requireCommand(c.audience);const r=master(raw),f=fields(r,data,true),ks=Object.keys(f);await requireRuntimePermission(db,c,r+'.create');const values=[c.tenant_id,c.scope_id,...Object.values(f)];return (await db.query(`INSERT INTO ${table(r)} (tenant_id,scope_id,${ks.map(ident).join(',')}) VALUES (${values.map((_,i)=>'$'+(i+1)).join(',')}) RETURNING id,version`,values)).rows[0];});}
 @Patch('masters/:resource/:id') update(@Headers('authorization') h:string,@Headers('x-app-audience') a:string,@Param('resource') raw:string,@Param('id') id:string,@Body() data:{version:unknown;fields:unknown}){return this.db.run(h,a,async(db,c)=>{requireCommand(c.audience);const r=master(raw),v=revision(data?.version),f=fields(r,data?.fields,false);await requireRuntimePermission(db,c,r+'.update');const values=[c.tenant_id,uuid(id),v,c.scope_id,...Object.values(f)];const x=await db.query(`UPDATE ${table(r)} SET ${Object.keys(f).map((k,i)=>ident(k)+'=$'+(i+5)).join(',')} WHERE tenant_id=$1 AND id=$2 AND version=$3 AND ($4::uuid IS NULL OR scope_id=$4) AND archived_at IS NULL ${r==='catalog.product'?"AND status='DRAFT'":''} RETURNING id,version`,values);if(!x.rowCount)throw new Fault(409,'STALE_OR_INACCESSIBLE');return x.rows[0];});}
 @Post('masters/:resource/:id/archive') @HttpCode(200) archive(@Headers('authorization') h:string,@Headers('x-app-audience') a:string,@Param('resource') raw:string,@Param('id') id:string,@Body() data:{version:unknown;restore?:unknown}){return this.db.run(h,a,async(db,c)=>{requireCommand(c.audience);const r=master(raw),restore=data?.restore===true;await requireRuntimePermission(db,c,r+'.update');const x=await db.query(`UPDATE ${table(r)} SET archived_at=${restore?'NULL':'clock_timestamp()'} WHERE tenant_id=$1 AND id=$2 AND version=$3 AND ($4::uuid IS NULL OR scope_id=$4) AND archived_at IS ${restore?'NOT ':''}NULL ${r==='catalog.product'?"AND status='DRAFT'":''} RETURNING id,version`,[c.tenant_id,uuid(id),revision(data?.version),c.scope_id]);if(!x.rowCount)throw new Fault(409,'STALE_OR_INACCESSIBLE');return x.rows[0];});}
 @Post('sync/drafts') @HttpCode(200) sync(@Headers('authorization') h:string,@Headers('x-app-audience') a:string,@Body() data:{id:unknown;lines:unknown}){return this.db.run(h,a,async(db,c)=>{if(c.audience!=='retailer'||!c.scope_id)throw new Fault(403,'RETAILER_SCOPE_REQUIRED');const ent=await db.query('SELECT * FROM app_private.retail_entitlement($1,$2,$3)',[c.tenant_id,c.membership_id,c.scope_id]);if(ent.rows[0]?.can_price!==true)throw new Fault(403,'KYC_APPROVAL_REQUIRED');const lines=validateDraft(data?.lines);return (await db.query('SELECT * FROM app_private.receive_retailer_draft($1,$2,$3,$4::jsonb)',[c.tenant_id,c.scope_id,uuid(data?.id),JSON.stringify(lines)])).rows[0];});}
 @Post('webhooks/:provider') @HttpCode(503) webhook(){return {code:'PROVIDER_NOT_CERTIFIED'};}
}
@Module({controllers:[Api],providers:[Db]}) class AppModule{}
async function main(){const env=validateRuntimeEnv(process.env);
 const probe=new Pool({connectionString:env.RUNTIME_DATABASE_URL,connectionTimeoutMillis:5000,statement_timeout:5000,max:1});
 try{const result=await probe.query<{safe:boolean}>(`SELECT NOT (r.rolsuper OR r.rolbypassrls OR r.rolcreatedb OR r.rolcreaterole OR r.rolinherit) AND pg_has_role(current_user,'wholesale_runtime','MEMBER') AS safe FROM pg_roles r WHERE r.rolname=current_user`);if(result.rows[0]?.safe!==true)throw new Error('Unsafe runtime database role');const client=await probe.connect();try{await client.query('BEGIN');await client.query('SET LOCAL ROLE wholesale_runtime');await client.query('ROLLBACK');}finally{client.release();}}catch{throw new Error('Database startup certification failed');}finally{await probe.end();}
 const app=await NestFactory.create(AppModule,{bodyParser:true});app.enableShutdownHooks();await app.listen(env.PORT,'127.0.0.1');}void main().catch(e=>{console.error(e instanceof Error?e.message:'Startup failed');process.exitCode=1;});
