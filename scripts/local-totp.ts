import {totpAt} from '../packages/core/auth.ts';
const n=process.argv[2];if(process.env.AUTH_MODE!=='dev'||process.env.ALLOW_LOCAL_DEV_OTP!=='YES'||!['03','04','05','06','07','08'].includes(n))throw new Error('Usage: local dev only; choose 03,04,05,06,07,08');
const phone='+96475000000'+n;const secret=(JSON.parse(process.env.AUTH_STAFF_TOTP_JSON??'{}') as Record<string,string>)[phone];console.log(totpAt(secret,Math.floor(Date.now()/30000)));
