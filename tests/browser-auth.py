"""Real Chromium browser UI login; no manual cookie injection or mocked API.
Requires isolated Step A/B services and synthetic fixture account 08.
Never print challenge codes, session values, or authenticator secrets.
"""
import json, os, re, subprocess
from pathlib import Path
from playwright.sync_api import sync_playwright, expect
ROOT=Path(__file__).resolve().parents[1]
assert os.environ.get('AUTH_MODE')=='dev' and os.environ.get('ALLOW_LOCAL_DEV_OTP')=='YES'
assert os.environ.get('AUTH_RETAILER_SIGNUP_TENANT')=='wholesale-local'
assert re.fullmatch(r'postgresql://wholesale_stepab_login:[0-9a-f]+@127\.0\.0\.1:55432/wholesale_test',os.environ.get('RUNTIME_DATABASE_URL',''))
checks=[]
def passed(name):
    checks.append(name); print('PASS:',name,flush=True)
def api(page,path):
    return page.evaluate('''async path=>{const r=await fetch('/api/enterprise/'+path,{cache:'no-store'});return {status:r.status,data:await r.json()}}''',path)
def login(page,port,phone,audience,staff=False):
    page.goto(f'http://localhost:{port}/',wait_until='domcontentloaded')
    page.get_by_label('Organization code').fill('wholesale-local')
    page.get_by_label('Iraqi mobile number').fill(phone)
    page.get_by_label('I consent to receive a verification message').check()
    page.get_by_role('button',name='Send WhatsApp code',exact=True).click()
    otp=page.locator('p[role=status] bdi');expect(otp).to_have_text(re.compile(r'^\d{6}$'))
    page.get_by_label('Verification code',exact=True).fill(otp.inner_text())
    if staff:
        code=subprocess.check_output(['node','--experimental-strip-types','scripts/local-totp.ts','08'],cwd=ROOT,text=True).strip()
        assert re.fullmatch(r'\d{6}',code),'TOTP fixture output invalid'
        page.get_by_label('Authenticator code',exact=True).fill(code)
    with page.expect_response(lambda r:r.url.endswith('/api/enterprise/auth/otp/verify')) as response:
        page.get_by_role('button',name='Verify and sign in',exact=True).click()
    r=response.value; assert r.status==200,'Browser verification failed'
    body=r.json(); assert body.get('authenticated') is True and 'token' not in body
    expect(page.get_by_role('button',name='Sign out',exact=True)).to_be_visible()
    name='__Host-wholesale-session-'+audience
    cookies=[c for c in page.context.cookies() if c['name']==name]
    assert len(cookies)==1,'Browser did not store session cookie'
    c=cookies[0]; assert c['httpOnly'] and c['secure'] and c['sameSite']=='Strict' and c['path']=='/'
    assert c['domain']=='localhost','Unexpected cookie domain'
    assert name not in page.evaluate('document.cookie'),'HttpOnly cookie visible to script'
    assert page.evaluate('''name=>!Object.entries(localStorage).concat(Object.entries(sessionStorage)).some(([k,v])=>k.includes('session-token')||v.includes(name))''',c['value']),'Session token present in web storage'
    s=api(page,'session');assert s['status']==200 and s['data']['audience']==audience
    passed(audience+' actual UI login and browser-managed secure HttpOnly session')
    page.reload(wait_until='domcontentloaded');expect(page.get_by_role('button',name='Sign out',exact=True)).to_be_visible()
    assert api(page,'session')['status']==200
    passed(audience+' session persists on actual reload')
def logout(page,audience):
    page.get_by_role('button',name='Sign out',exact=True).click()
    expect(page.get_by_label('Organization code')).to_be_visible()
    assert api(page,'session')['status']==401
    assert not any(c['name']=='__Host-wholesale-session-'+audience for c in page.context.cookies())
    passed(audience+' actual UI logout clears browser session')
with sync_playwright() as p:
    browser=p.chromium.launch()
    ctx=browser.new_context();page=ctx.new_page();page.set_default_timeout(20000)
    login(page,3001,'+9647500000010','retailer')
    catalog=api(page,'retailer/catalog')
    assert catalog['status']==200 and any(x['sku']=='FIXTURE-001' for x in catalog['data'])
    assert all('price_rules' not in x and x['sku']!='OTHER-TENANT-SECRET' for x in catalog['data'])
    passed('preview catalog price omission and tenant isolation in browser')
    command=ctx.new_page();command.goto('http://localhost:3005/',wait_until='domcontentloaded')
    expect(command.get_by_label('Organization code')).to_be_visible()
    assert api(command,'session')['status']==401
    passed('retailer browser cookie does not authorize Command Centre')
    other=browser.new_context();isolated=other.new_page();isolated.goto('http://localhost:3001/',wait_until='domcontentloaded')
    assert api(isolated,'session')['status']==401;other.close()
    passed('independent browser context has no inherited session')
    login(command,3005,'+9647500000008','command',staff=True)
    assert api(page,'session')['data']['audience']=='retailer'
    assert api(command,'session')['data']['audience']=='command'
    passed('retailer and staff cookies coexist without audience substitution')
    logout(command,'command');assert api(page,'session')['status']==200
    passed('staff logout does not revoke retailer audience')
    logout(page,'retailer');ctx.close();browser.close()
print(json.dumps({'status':'PASS','checks':checks},indent=2))
