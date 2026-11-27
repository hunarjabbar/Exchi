import {enterpriseProxy} from '@wholesale/ui/proxy';
const proxy=enterpriseProxy('retailer');
export {proxy as GET,proxy as POST,proxy as PATCH};
