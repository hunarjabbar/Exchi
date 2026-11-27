from pathlib import Path
import re, json
r=Path(__file__).resolve().parents[1]
f=(r/'prisma/migrations/202611270001_foundation/migration.sql').read_text()
c=(r/'prisma/migrations/202611270002_controls/migration.sql').read_text()
s=(r/'prisma/migrations/202611270003_reference/migration.sql').read_text()
p=(r/'prisma/schema.prisma').read_text()
reg=json.loads((r/'docs/model-registry.json').read_text())
# These checks validate artifact consistency, not PostgreSQL or Prisma execution.
tables=re.findall(r'CREATE TABLE ("?\w+"?\.\w+) \(',f)
models=re.findall(r'(?m)^model (\w+) \{',p)
assert len(tables)==len(models)==len(reg)==111
for name,m in reg.items():
    ident=m['schema']+'.'+name
    sql_ident=('"'+m['schema']+'"' if m['schema'] in ['authorization','returns'] else m['schema'])+'.'+name
    assert sql_ident in tables,ident
    assert f'@@map("{name}")' in p
    if not m['global_']:
        assert f'ALTER TABLE {sql_ident} ENABLE ROW LEVEL SECURITY' in c,ident
        assert f'ALTER TABLE {sql_ident} FORCE ROW LEVEL SECURITY' in c,ident
        assert f"'{ident}.read'" in c,ident
        if m['mode']!='audit': assert f'CREATE TRIGGER audit_mutation AFTER INSERT OR UPDATE OR DELETE ON {sql_ident}' in c,ident
        if m['mode'] in ('append','audit'): assert f'CREATE TRIGGER immutable BEFORE UPDATE OR DELETE ON {sql_ident}' in c,ident
    for k,t,nu,d,ref,glob in m['parsed']:
        if ref:
            assert f'ADD CONSTRAINT fk_{name}_{k} FOREIGN KEY' in f,(name,k)
            assert f'map: "fk_{name}_{k}"' in p,(name,k)
assert len(re.findall(r"^\('[A-Z]{3}',",s.split("INSERT INTO payments.provider")[0],re.M))==19
assert "('HAL','Halabja'" in s
assert "'FINANCIAL_POSTING'" in c and "'TRADE_CREDIT'" in c and "'DIGITAL_PAYMENTS'" in c
assert re.search(r'CREATE TABLE payments.provider \([\s\S]*?status text NOT NULL DEFAULT \'DISABLED\'',f)
assert not re.search(r'GRANT [^;]*DELETE[^;]*TO wholesale_runtime',c)
assert 'verified_intent_id' in f and 'VerifiedWebhookIntent' in p
assert 'wi.verified_intent_id IS DISTINCT FROM i' in c
assert 'ROLLBACK;' in (r/'tests/acceptance.sql').read_text()
print(f'PASS: {len(tables)} table/model mappings; {sum(not m["global_"] for m in reg.values())} tenant RLS configurations; {len(re.findall("FOREIGN KEY",f))} foundation foreign keys; 19 governorate rows; policy and audit markers.')
print('LIMITATION: no SQL execution, Prisma compiler, RLS runtime, or concurrency verification performed by this script.')
