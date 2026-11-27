import {readFileSync,writeFileSync,lstatSync,renameSync,unlinkSync} from 'node:fs';
import {randomBytes} from 'node:crypto';
const path='.local-stepab.env', stat=lstatSync(path);
if(!stat.isFile()||stat.isSymbolicLink()||(stat.mode&0o077)!==0)throw new Error('Expected private regular .local-stepab.env');
const src=readFileSync(path,'utf8');
if(!/^AUTH_MODE='dev'$/m.test(src)||!/^ALLOW_LOCAL_DEV_OTP='YES'$/m.test(src)||!/^AUTH_RETAILER_SIGNUP_TENANT='wholesale-local'$/m.test(src)||!/^RUNTIME_DATABASE_URL='postgresql:\/\/wholesale_stepab_login:[0-9a-f]+@127\.0\.0\.1:55432\/wholesale_test'$/m.test(src))throw new Error('Refusing non-local fixture');
const match=src.match(/^AUTH_STAFF_TOTP_JSON='([^'\n]+)'$/m);if(!match)throw new Error('Missing local authenticator map');
const factors=JSON.parse(match[1]),phone='+9647500000008';
if(Object.hasOwn(factors,phone)){if(!/^[0-9a-f]{40}$/.test(factors[phone]))throw new Error('Invalid existing test fixture');console.log('Local browser fixture already configured.');process.exit(0);}
factors[phone]=randomBytes(20).toString('hex');
const temp=path+'.'+randomBytes(8).toString('hex')+'.tmp';
try{writeFileSync(temp,src.replace(match[0],`AUTH_STAFF_TOTP_JSON='${JSON.stringify(factors)}'`),{mode:0o600,flag:'wx'});renameSync(temp,path);}finally{try{unlinkSync(temp)}catch{}}
console.log('Local browser fixture 08 configured; existing credentials preserved.');
