"""Two concurrent PostgreSQL sessions against a newly created, isolated test DB.
No financial policy is enabled in the main local database or any real environment.
"""
import os, re, subprocess, uuid, concurrent.futures
from pathlib import Path
from urllib.parse import urlsplit, urlunsplit
root=Path(__file__).resolve().parents[1]
base=urlsplit(os.environ['DATABASE_URL'])
if os.environ.get('ALLOW_DISPOSABLE_DB_TEST')!='YES' or base.scheme!='postgresql' or base.hostname!='127.0.0.1' or base.port!=55432 or base.username!='postgres' or base.path!='/wholesale_test':
    raise SystemExit('Refusing non-local test database')
name='wholesale_concurrency_'+uuid.uuid4().hex[:12]
main=urlunsplit((base.scheme,base.netloc,base.path,'',''))
url=urlunsplit((base.scheme,base.netloc,'/'+name,'',''))
def psql(db, sql, check=True):
    p=subprocess.run(['psql',db,'-X','-qAt','-v','ON_ERROR_STOP=1'],input=sql,text=True,capture_output=True,timeout=60)
    if check and p.returncode: raise RuntimeError(p.stderr.strip())
    return p
psql(main,f'CREATE DATABASE {name};')
try:
    for f in sorted((root/'packages/database/prisma/migrations').glob('*/migration.sql')):
        psql(url,f.read_text())
    original=(root/'packages/database/tests/acceptance.sql').read_text()
    fixture,separator,_=original.partition("SELECT set_config('app.tenant_id',")
    assert separator and 'INSERT INTO inventory.stock_balance' in fixture and 'INSERT INTO credit.facility' in fixture and 'SET LOCAL ROLE' not in fixture
    psql(url,fixture+"\nINSERT INTO compliance.policy(tenant_id,code,jurisdiction,source_ref,effective_from,configuration,status) VALUES('00000000-0000-4000-8000-000000000001','TRADE_CREDIT','SYNTHETIC_TEST_ONLY','TEST',now()-interval '1 day','{}','ACTIVE');\nCOMMIT;")
    prefix="BEGIN; SET LOCAL ROLE wholesale_runtime; SELECT set_config('app.tenant_id','00000000-0000-4000-8000-000000000001',true),set_config('app.membership_id','00000000-0000-4000-8000-000000000006',true);\n"
    def race(a,b,expected):
        def run(command): return psql(url,prefix+command+'; SELECT pg_sleep(1); COMMIT;',False)
        with concurrent.futures.ThreadPoolExecutor(max_workers=2) as ex:
            fs=[ex.submit(run,x) for x in [a,b]]; results=[f.result() for f in fs]
        good=[r for r in results if r.returncode==0]; bad=[r for r in results if r.returncode!=0]
        if len(good)!=1 or len(bad)!=1 or expected not in bad[0].stderr:
            raise RuntimeError('concurrency assertion failed: '+str([(r.returncode,r.stderr.strip()) for r in results]))
    race(*[f"SELECT app_private.reserve_stock('00000000-0000-4000-8000-000000000001','00000000-0000-4000-8000-000000000050','00000000-0000-4000-8000-0000000000{x}',8)" for x in ['42','46']], 'insufficient stock')
    psql(url,"DO $$ BEGIN IF NOT coalesce((SELECT reserved=8 FROM inventory.stock_balance WHERE id='00000000-0000-4000-8000-000000000050'),false) THEN RAISE EXCEPTION 'stock race invariant'; END IF; END $$;")
    print('PASS: concurrent stock reservations: one committed, one rejected; 8 units reserved out of 10')
    race(*[f"SELECT app_private.commit_credit('00000000-0000-4000-8000-000000000001','00000000-0000-4000-8000-000000000051','00000000-0000-4000-8000-0000000000{x}',100)" for x in ['41','45']], 'credit limit exceeded')
    psql(url,"DO $$ BEGIN IF (SELECT count(*) FROM credit.commitment WHERE facility_id='00000000-0000-4000-8000-000000000051')<>1 THEN RAISE EXCEPTION 'credit race invariant'; END IF; END $$;")
    print('PASS: concurrent credit commitments: one committed, one rejected; 100 of 150 limit')
finally:
    assert re.fullmatch(r'wholesale_concurrency_[0-9a-f]{12}',name)
    psql(main,f'DROP DATABASE {name} WITH (FORCE);')
