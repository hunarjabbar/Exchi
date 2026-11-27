import {Shell} from '@wholesale/ui/shell';
import {notFound,redirect} from 'next/navigation';
const allowed=["/supplier/home", "/supplier/catalog", "/supplier/inventory", "/supplier/orders", "/supplier/promotions", "/supplier/settlements"];
export default async function Page({params}:{params:Promise<{segments?:string[]}>}){const p=await params;if(!p.segments?.length)redirect(allowed[0]);const path='/'+p.segments.join('/');if(!allowed.includes(path))notFound();return <Shell audience="supplier" path={path}/>;}
