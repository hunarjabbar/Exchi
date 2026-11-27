\set ON_ERROR_STOP on
BEGIN;
-- Execute as migration administrator on disposable database AFTER fixture seed.
DO $$
DECLARE cid uuid:=gen_random_uuid(); d text:=repeat('a',64); tok text:=repeat('b',64); t uuid; m uuid; s uuid; step bigint:=floor(extract(epoch FROM clock_timestamp())/30)::bigint; x jsonb;
BEGIN
 IF current_database()<>'wholesale_test' THEN RAISE EXCEPTION 'test database required'; END IF;
 IF NOT app_private.begin_otp(cid,'+9647500000090','wholesale-local','retailer',d,'DEV') THEN RAISE EXCEPTION 'challenge not created'; END IF;
 IF app_private.begin_otp(gen_random_uuid(),'+9647500000090','wholesale-local','command',d,'DEV') THEN RAISE EXCEPTION 'cross-audience cooldown bypass'; END IF;
 IF app_private.finish_otp(cid,'+9647500000090','wholesale-local','command',d,tok,step,true) THEN RAISE EXCEPTION 'audience binding bypass'; END IF;
 IF app_private.finish_otp(cid,'+9647500000090','wholesale-local','retailer',repeat('c',64),tok,NULL,true) THEN RAISE EXCEPTION 'invalid code accepted'; END IF;
 IF NOT app_private.finish_otp(cid,'+9647500000090','wholesale-local','retailer',d,tok,NULL,true) THEN RAISE EXCEPTION 'retail signup failed'; END IF;
 IF app_private.finish_otp(cid,'+9647500000090','wholesale-local','retailer',d,repeat('e',64),NULL,true) THEN RAISE EXCEPTION 'challenge replay accepted'; END IF;
 SELECT tenant_id,membership_id,scope_id INTO t,m,s FROM app_private.resolve_login(tok,'retailer'); IF m IS NULL THEN RAISE EXCEPTION 'session not resolved'; END IF;
 IF EXISTS(SELECT 1 FROM app_private.resolve_login(tok,'command')) THEN RAISE EXCEPTION 'session audience mismatch accepted'; END IF;
 PERFORM set_config('app.tenant_id',t::text,true); PERFORM set_config('app.membership_id',m::text,true);
 IF NOT EXISTS(SELECT 1 FROM app_private.retail_entitlement(t,m,s) WHERE NOT can_price AND tier='PREVIEW') THEN RAISE EXCEPTION 'preview status wrong'; END IF;
 IF NOT EXISTS(SELECT 1 FROM app_private.retail_catalog(t,m,s) AS a(item) WHERE item->>'sku'='FIXTURE-001') OR EXISTS(SELECT 1 FROM app_private.retail_catalog(t,m,s) AS a(item) WHERE item ? 'price_rules' OR item->>'sku'='OTHER-TENANT-SECRET') THEN RAISE EXCEPTION 'preview catalog leakage or missing fixture'; END IF;
 PERFORM app_private.logout_login(tok,'retailer'); IF EXISTS(SELECT 1 FROM app_private.resolve_login(tok,'retailer')) THEN RAISE EXCEPTION 'logout failed'; END IF;
 cid:=gen_random_uuid(); IF NOT app_private.begin_otp(cid,'+9647500000002','wholesale-local','retailer',d,'DEV') THEN RAISE EXCEPTION 'approved buyer challenge not created'; END IF;
 IF NOT app_private.finish_otp(cid,'+9647500000002','wholesale-local','retailer',d,repeat('2',64),NULL,false) THEN RAISE EXCEPTION 'approved buyer login failed'; END IF;
 SELECT tenant_id,membership_id,scope_id INTO t,m,s FROM app_private.resolve_login(repeat('2',64),'retailer');
 PERFORM set_config('app.tenant_id',t::text,true); PERFORM set_config('app.membership_id',m::text,true);
 IF NOT EXISTS(SELECT 1 FROM app_private.retail_entitlement(t,m,s) WHERE can_price AND tier='STANDARD') THEN RAISE EXCEPTION 'approved entitlement missing'; END IF;
 SELECT item INTO x FROM app_private.retail_catalog(t,m,s) AS a(item) WHERE item->>'sku'='FIXTURE-001';
 IF x IS NULL OR jsonb_array_length(x->'price_rules') IS DISTINCT FROM 1 OR (x->'price_rules'->0->>'amount')::numeric IS DISTINCT FROM 24000::numeric THEN RAISE EXCEPTION 'tier leak or wrong price'; END IF;
 UPDATE compliance.kyc_case SET status='SUSPENDED' WHERE tenant_id=t AND scope_id=s;
 IF NOT EXISTS(SELECT 1 FROM app_private.retail_entitlement(t,m,s) WHERE NOT can_price) OR EXISTS(SELECT 1 FROM app_private.retail_catalog(t,m,s) AS a(item) WHERE item ? 'price_rules') THEN RAISE EXCEPTION 'KYC revocation not enforced'; END IF;
 PERFORM app_private.logout_login(repeat('2',64),'retailer');

 cid:=gen_random_uuid(); IF NOT app_private.begin_otp(cid,'+9647500000091','wholesale-local','retailer',d,'DEV') THEN RAISE EXCEPTION 'challenge not created'; END IF;
 FOR i IN 1..5 LOOP IF app_private.finish_otp(cid,'+9647500000091','wholesale-local','retailer',repeat('f',64),tok,NULL,true) THEN RAISE EXCEPTION 'bad code accepted'; END IF; END LOOP;
 IF app_private.finish_otp(cid,'+9647500000091','wholesale-local','retailer',d,tok,NULL,true) THEN RAISE EXCEPTION 'attempt cap bypass'; END IF;
 cid:=gen_random_uuid(); IF NOT app_private.begin_otp(cid,'+9647500000092','wholesale-local','retailer',d,'DEV') THEN RAISE EXCEPTION 'challenge not created'; END IF;
 UPDATE identity.otp_challenge SET expires_at=now()-interval '1 second' WHERE id=cid;
 IF app_private.finish_otp(cid,'+9647500000092','wholesale-local','retailer',d,tok,NULL,true) THEN RAISE EXCEPTION 'expired code accepted'; END IF;
 cid:=gen_random_uuid(); IF NOT app_private.begin_otp(cid,'+9647500000008','wholesale-local','command',d,'DEV') THEN RAISE EXCEPTION 'command challenge not created'; END IF;
 IF app_private.finish_otp(cid,'+9647500000008','wholesale-local','command',d,tok,NULL,false) THEN RAISE EXCEPTION 'staff MFA bypass'; END IF;
 IF NOT app_private.finish_otp(cid,'+9647500000008','wholesale-local','command',d,repeat('3',64),step,false) THEN RAISE EXCEPTION 'staff login failed'; END IF;
 IF NOT EXISTS(SELECT 1 FROM app_private.resolve_login(repeat('3',64),'command')) THEN RAISE EXCEPTION 'staff session missing'; END IF;
 UPDATE identity.otp_challenge SET created_at=now()-interval '61 seconds' WHERE id=cid; cid:=gen_random_uuid();
 IF NOT app_private.begin_otp(cid,'+9647500000008','wholesale-local','command',d,'DEV') THEN RAISE EXCEPTION 'staff second challenge not created'; END IF;
 IF app_private.finish_otp(cid,'+9647500000008','wholesale-local','command',d,repeat('4',64),step,false) THEN RAISE EXCEPTION 'TOTP replay accepted'; END IF;
 UPDATE "authorization".assignment SET archived_at=now() WHERE membership_id=(SELECT membership_id FROM app_private.resolve_login(repeat('3',64),'command'));
 IF EXISTS(SELECT 1 FROM app_private.resolve_login(repeat('3',64),'command')) THEN RAISE EXCEPTION 'role revocation not enforced'; END IF;
END $$;
SET LOCAL ROLE wholesale_runtime;
DO $$ BEGIN IF has_table_privilege(current_user,'identity.otp_challenge','SELECT') OR has_table_privilege(current_user,'identity.session','SELECT') OR has_table_privilege(current_user,'identity.principal','SELECT') THEN RAISE EXCEPTION 'auth secrets exposed'; END IF; END $$;
RESET ROLE;
ROLLBACK;
\echo Step A/B SQL auth acceptance passed
