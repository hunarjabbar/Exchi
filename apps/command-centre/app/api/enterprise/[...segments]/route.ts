import {enterpriseProxy} from '@wholesale/ui/proxy';
const proxy=enterpriseProxy('command');
export {proxy as GET,proxy as POST,proxy as PATCH};
