import {enterpriseProxy} from '@wholesale/ui/proxy';
const proxy=enterpriseProxy('public');
export {proxy as GET,proxy as POST,proxy as PATCH};
