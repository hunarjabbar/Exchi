import {randomBytes} from 'node:crypto';
import {writeFileSync} from 'node:fs';
const hex=n=>randomBytes(n).toString('hex');
const owner=hex(24),runtime=hex(24),hmac=hex(32);
const factors=Object.fromEntries([3,4,5,6,7,8].map(n=>['+96475000000'+String(n).padStart(2,'0'),hex(20)]));
const vars={WHOLESALE_LOCAL_DB_PASSWORD:owner,WHOLESALE_LOCAL_RUNTIME_PASSWORD:runtime,DATABASE_URL:`postgresql://postgres:${owner}@127.0.0.1:55432/wholesale_test?schema=public`,RUNTIME_DATABASE_URL:`postgresql://wholesale_stepab_login:${runtime}@127.0.0.1:55432/wholesale_test`,AUTH_OTP_HMAC_KEY:hmac,AUTH_MODE:'dev',ALLOW_LOCAL_DEV_OTP:'YES',AUTH_RETAILER_SIGNUP_TENANT:'wholesale-local',AUTH_STAFF_TOTP_JSON:JSON.stringify(factors),ENTERPRISE_API_URL:'http://127.0.0.1:4000',ALLOW_DISPOSABLE_DB_TEST:'YES'};
writeFileSync('.local-stepab.env',Object.entries(vars).map(([k,v])=>`${k}='${v}'`).join('\n')+'\n',{mode:0o600,flag:'wx'});
console.log('Created private .local-stepab.env. Never commit or share it.');
