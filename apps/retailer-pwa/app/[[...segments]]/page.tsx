import {Shell} from '@wholesale/ui/shell';
import {notFound,redirect} from 'next/navigation';
const allowed=["/app/home", "/app/catalog", "/app/search", "/app/scan", "/app/quick-order", "/app/cart", "/app/checkout", "/app/orders", "/app/orders/detail", "/app/rfq", "/app/credit", "/app/invoices", "/app/returns", "/app/account/stores", "/app/account/team", "/app/account/documents", "/app/notifications", "/app/sync"];
export default async function Page({params}:{params:Promise<{segments?:string[]}>}){const p=await params;if(!p.segments?.length)redirect(allowed[0]);const path='/'+p.segments.join('/');if(!allowed.includes(path))notFound();return <Shell audience="retailer" path={path}/>;}
