from pathlib import Path
from playwright.sync_api import sync_playwright
import json, subprocess, tempfile
root=Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory() as tmp:
    subprocess.run(['tsc','--target','ES2022','--module','ES2022','--moduleResolution','bundler','--rewriteRelativeImportExtensions','--strict','--lib','ES2022,DOM','--rootDir','packages','--outDir',tmp,'packages/core/index.ts','packages/ui/offline.ts'],cwd=root,check=True)
    files=Path(tmp)
    with sync_playwright() as p:
        b=p.chromium.launch(executable_path='/usr/bin/chromium' if Path('/usr/bin/chromium').exists() else None,args=['--no-sandbox']); ctx=b.new_context(); page=ctx.new_page()
        def route(r):
            path=r.request.url.split('https://wholesale.test/',1)[-1]
            if path in ('','index.html'): r.fulfill(content_type='text/html',body='<!doctype html><title>IndexedDB test</title>')
            elif path in ('core/index.js','ui/offline.js'): r.fulfill(content_type='text/javascript',body=(files/path).read_text())
            else: r.abort()
        page.route('https://wholesale.test/**',route);page.goto('https://wholesale.test/')
        result=page.evaluate('''async()=>{const m=await import('/ui/offline.js');const a=await m.saveDraft('tenant-a:member-a:retailer',[{sku:'A',cartons:20}]);const b=await m.saveDraft('tenant-b:member-b:retailer',[{sku:'B',cartons:10}]);let invalid=false;try{await m.saveDraft('tenant-a:member-a:retailer',[{sku:'X',cartons:-1}])}catch{invalid=true}return {a,b,partitionA:(await m.drafts('tenant-a:member-a:retailer')).length,partitionB:(await m.drafts('tenant-b:member-b:retailer')).length,invalid}}''')
        assert result['partitionA']==result['partitionB']==1 and result['invalid']
        page.reload(); assert page.evaluate("async()=>{const m=await import('/ui/offline.js');return (await m.drafts('tenant-a:member-a:retailer'))[0].lines[0].cartons}")==20
        page.evaluate("async(id)=>{const m=await import('/ui/offline.js');await m.acknowledgeDraft('tenant-a:member-a:retailer',id)}",result['a']['id'])
        assert page.evaluate("async()=>{const m=await import('/ui/offline.js');return (await m.drafts('tenant-a:member-a:retailer'))[0].state}")=='REQUOTE_REQUIRED'
        page.evaluate("async()=>{const m=await import('/ui/offline.js');await m.clearPartition('tenant-a:member-a:retailer')}")
        assert page.evaluate("async()=>{const m=await import('/ui/offline.js');return (await m.drafts('tenant-a:member-a:retailer')).length===0&&(await m.drafts('tenant-b:member-b:retailer')).length===1}")
        b.close()
print(json.dumps({'status':'PASS','checks':['actual IndexedDB write','partition isolation','invalid quantity rejection','reload persistence','receipt state update','partition-only deletion'],'scope':'Chromium storage module; no Next.js or API/database exercised'},indent=2))
