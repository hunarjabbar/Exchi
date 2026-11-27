import {enterpriseProxy} from '@wholesale/ui/proxy';
const proxy=enterpriseProxy('supplier');
export {proxy as GET,proxy as POST,proxy as PATCH};
