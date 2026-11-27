from pathlib import Path
import json, re, hashlib
r=Path(__file__).resolve().parents[1]
original=json.loads((r/'docs/design-system/routes.json').read_text()); routes=json.loads((r/'packages/contracts/routes.json').read_text()); registry=json.loads((r/'packages/database/docs/model-registry.json').read_text())
assert len(routes)==len(original)==70 and len({x['path'] for x in routes})==70
assert {(x['role'],x['path']) for x in routes}=={(x['role'],x['path']) for x in original}
assert sum(x['role']=='command' for x in routes)==31
roles={'public':'public-web','retailer':'retailer-pwa','supplier':'distributor-portal','field':'field-sales-pwa','driver':'driver-pwa','command':'command-centre'}
for role,folder in roles.items():
 app=r/'apps'/folder; p=(app/'app/[[...segments]]/page.tsx').read_text(); paths=json.loads(re.search(r'const allowed=(\[.*\]);',p).group(1));assert paths==[x['path'] for x in routes if x['role']==role]
 assert 'notFound()' in p and 'redirect(allowed[0])' in p
 proxy=(app/'app/api/enterprise/[...segments]/route.ts').read_text();assert f"enterpriseProxy('{role}')" in proxy
 shared=(r/'packages/ui/proxy.ts').read_text();assert '__Host-wholesale-session-' in shared and 'ORIGIN_DENIED' in shared and 'no-store' in shared
 assert (app/'public/manifest.webmanifest').exists() and (app/'public/sw.js').exists()
 for route in [x for x in routes if x['role']==role and x['readColumns']]:
  assert role=='command'; m=registry[route['resource'].split('.')[-1]]; cols={x[0] for x in m['parsed']}; assert set(route['readColumns'])<=cols
  assert not set(route['readColumns']) & {'token_digest','public_key','credential_id','secret_ref','payload','object_key','before_data','after_data','payload_hash','tax_id','registration_no','phone','address_id'}
assert len(list((r/'packages/database/prisma/migrations').glob('*/migration.sql')))==8
assert 'payload Json?' in (r/'packages/database/prisma/schema.prisma').read_text()
assert 'REVOKE SELECT ON identity.session,identity.device' in (r/'packages/database/prisma/migrations/202611270004_session_boundary/migration.sql').read_text()
assert 'REQUOTE_REQUIRED' in (r/'packages/database/prisma/migrations/202611270005_draft_inbox/migration.sql').read_text()
api=(r/'apps/enterprise-api/src/main.ts').read_text();assert 'SET LOCAL ROLE wholesale_runtime' in api and "app.membership_id" in api and 'PROVIDER_NOT_CERTIFIED' in api
assert not any(s in api for s in ['app_private.post_journal','app_private.confirm_payment','app_private.commit_credit'])
print('PASS: 70 canonical routes, 31 command workspaces, six fixed application audiences, eight migrations, scoped projection field validation, protected payment/credit/posting endpoints absent.')
print('Static assertions only; database policy and application behavior require runtime acceptance.')
