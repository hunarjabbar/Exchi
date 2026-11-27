\set ON_ERROR_STOP on
BEGIN;
INSERT INTO organizations.tenant(id,code,name) VALUES('51000000-0000-4000-8000-000000000001','phase5-test','Phase 5 test');
INSERT INTO identity.principal(id,phone,display_name) VALUES('51000000-0000-4000-8000-000000000002','+9647500000099','Synthetic retailer');
INSERT INTO organizations.scope(id,tenant_id,code,kind,name) VALUES('51000000-0000-4000-8000-000000000003','51000000-0000-4000-8000-000000000001','retail','RETAILER','Synthetic retail scope');
INSERT INTO organizations.membership(id,tenant_id,principal_id,scope_id) VALUES('51000000-0000-4000-8000-000000000004','51000000-0000-4000-8000-000000000001','51000000-0000-4000-8000-000000000002','51000000-0000-4000-8000-000000000003');
INSERT INTO organizations.party(id,tenant_id,scope_id,kind,code,name_en,status) VALUES('51000000-0000-4000-8000-000000000005','51000000-0000-4000-8000-000000000001','51000000-0000-4000-8000-000000000003','RETAILER','shop','Synthetic shop','ACTIVE');
INSERT INTO organizations.party_member(tenant_id,scope_id,party_id,membership_id,job_role) VALUES('51000000-0000-4000-8000-000000000001','51000000-0000-4000-8000-000000000003','51000000-0000-4000-8000-000000000005','51000000-0000-4000-8000-000000000004','OWNER');
INSERT INTO "authorization".role(id,tenant_id,code,name) VALUES('51000000-0000-4000-8000-000000000006','51000000-0000-4000-8000-000000000001','retail','Synthetic retail role');
INSERT INTO "authorization".role_permission(tenant_id,role_id,permission) VALUES('51000000-0000-4000-8000-000000000001','51000000-0000-4000-8000-000000000006','commerce.cart.create');
INSERT INTO "authorization".assignment(tenant_id,membership_id,role_id,assigned_scope_id) VALUES('51000000-0000-4000-8000-000000000001','51000000-0000-4000-8000-000000000004','51000000-0000-4000-8000-000000000006','51000000-0000-4000-8000-000000000003');
INSERT INTO identity.session(id,tenant_id,scope_id,membership_id,token_digest,audience,expires_at) VALUES('51000000-0000-4000-8000-000000000007','51000000-0000-4000-8000-000000000001','51000000-0000-4000-8000-000000000003','51000000-0000-4000-8000-000000000004',repeat('a',64),'retailer',now()+interval '1 hour');
SET LOCAL ROLE wholesale_runtime;
DO $$ BEGIN IF (SELECT count(*) FROM app_private.resolve_session(repeat('a',64),'retailer'))<>1 THEN RAISE EXCEPTION 'valid session not resolved'; END IF; IF EXISTS(SELECT 1 FROM app_private.resolve_session(repeat('a',64),'command')) THEN RAISE EXCEPTION 'audience bypass'; END IF; IF EXISTS(SELECT 1 FROM app_private.resolve_session(repeat('b',64),'retailer')) THEN RAISE EXCEPTION 'invalid digest accepted'; END IF; IF has_table_privilege(current_user,'identity.session','SELECT') OR has_table_privilege(current_user,'identity.device','SELECT') THEN RAISE EXCEPTION 'credential data exposed'; END IF; END $$;
SELECT set_config('app.tenant_id','51000000-0000-4000-8000-000000000001',true),set_config('app.membership_id','51000000-0000-4000-8000-000000000004',true);
DO $$ DECLARE a uuid;b uuid;st text;BEGIN
 SELECT receipt_id,state INTO a,st FROM app_private.receive_retailer_draft('51000000-0000-4000-8000-000000000001','51000000-0000-4000-8000-000000000003','51000000-0000-4000-8000-000000000008','[{"sku":"DEMO","cartons":20}]');
 SELECT receipt_id INTO b FROM app_private.receive_retailer_draft('51000000-0000-4000-8000-000000000001','51000000-0000-4000-8000-000000000003','51000000-0000-4000-8000-000000000008','[{"sku":"DEMO","cartons":20}]');
 IF a IS NULL OR a IS DISTINCT FROM b OR st<>'REQUOTE_REQUIRED' THEN RAISE EXCEPTION 'idempotent draft failure'; END IF;
 BEGIN PERFORM app_private.receive_retailer_draft('51000000-0000-4000-8000-000000000001','51000000-0000-4000-8000-000000000003','51000000-0000-4000-8000-000000000008','[{"sku":"DEMO","cartons":21}]'); RAISE EXCEPTION 'replay conflict not rejected'; EXCEPTION WHEN unique_violation THEN NULL; END;
 BEGIN PERFORM app_private.receive_retailer_draft('51000000-0000-4000-8000-000000000001','51000000-0000-4000-8000-000000000003','51000000-0000-4000-8000-000000000009','[{"sku":"DEMO","cartons":-2}]'); RAISE EXCEPTION 'negative quantity accepted'; EXCEPTION WHEN invalid_parameter_value THEN NULL; END;
 BEGIN PERFORM app_private.receive_retailer_draft('51000000-0000-4000-8000-000000000001',NULL,'51000000-0000-4000-8000-000000000009','[{"sku":"DEMO","cartons":1}]'); RAISE EXCEPTION 'scope bypass'; EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END $$;
RESET ROLE;
DO $$ BEGIN IF (SELECT count(*) FROM integrations.sync_operation WHERE tenant_id='51000000-0000-4000-8000-000000000001')<>1 OR EXISTS(SELECT 1 FROM commerce.sales_order WHERE tenant_id='51000000-0000-4000-8000-000000000001') THEN RAISE EXCEPTION 'draft affected commerce'; END IF; END $$;
UPDATE identity.session SET revoked_at=now() WHERE id='51000000-0000-4000-8000-000000000007';
SET LOCAL ROLE wholesale_runtime;
DO $$ BEGIN IF EXISTS(SELECT 1 FROM app_private.resolve_session(repeat('a',64),'retailer')) THEN RAISE EXCEPTION 'revoked session accepted'; END IF; END $$;
RESET ROLE;
ROLLBACK;
\echo Phase 5 session and draft acceptance passed
