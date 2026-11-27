import {Shell} from '@wholesale/ui/shell';
import {notFound,redirect} from 'next/navigation';
const allowed=["/field/home", "/field/territory", "/field/check-in", "/field/onboarding", "/field/proxy-order", "/field/collections", "/field/sync"];
export default async function Page({params}:{params:Promise<{segments?:string[]}>}){const p=await params;if(!p.segments?.length)redirect(allowed[0]);const path='/'+p.segments.join('/');if(!allowed.includes(path))notFound();return <Shell audience="field" path={path}/>;}
