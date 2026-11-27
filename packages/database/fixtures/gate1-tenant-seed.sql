\set ON_ERROR_STOP on
\getenv expected_db EXCHI_SEED_DATABASE
\getenv tenant_code EXCHI_TENANT_CODE
\getenv tenant_name EXCHI_TENANT_NAME
\getenv admin_phone EXCHI_BOOTSTRAP_PHONE
\getenv admin_name EXCHI_BOOTSTRAP_NAME
\getenv official_rate EXCHI_OFFICIAL_RATE
\getenv official_source EXCHI_OFFICIAL_SOURCE
\getenv indicative_rate EXCHI_INDICATIVE_RATE
\getenv indicative_source EXCHI_INDICATIVE_SOURCE
\getenv effective_from EXCHI_FX_EFFECTIVE_FROM
BEGIN;
SELECT set_config('exchi.seed.db', :'expected_db',true),set_config('exchi.seed.tenant', :'tenant_code',true),set_config('exchi.seed.name', :'tenant_name',true),set_config('exchi.seed.phone', :'admin_phone',true),set_config('exchi.seed.admin', :'admin_name',true),set_config('exchi.seed.official', :'official_rate',true),set_config('exchi.seed.official_source', :'official_source',true),set_config('exchi.seed.indicative', :'indicative_rate',true),set_config('exchi.seed.indicative_source', :'indicative_source',true),set_config('exchi.seed.effective', :'effective_from',true) \g /dev/null
DO $$
DECLARE t uuid; p uuid; m uuid; r uuid; x record; f record; tc text:=current_setting('exchi.seed.tenant'); nm text:=current_setting('exchi.seed.name'); ph text:=current_setting('exchi.seed.phone'); an text:=current_setting('exchi.seed.admin'); eff timestamptz:=current_setting('exchi.seed.effective')::timestamptz; fresh boolean;
BEGIN
 IF current_database()<>current_setting('exchi.seed.db') OR NOT EXISTS(SELECT 1 FROM pg_roles WHERE rolname=current_user AND (rolsuper OR rolbypassrls)) THEN RAISE EXCEPTION 'Wrong database or nonmigration owner'; END IF;
 IF tc !~ '^[a-z][a-z0-9-]{2,63}$' OR ph !~ '^\+9647[0-9]{9}$' OR length(trim(nm))<2 OR length(trim(an))<2 OR eff>now() THEN RAISE EXCEPTION 'Invalid tenant, administrator or FX effective date'; END IF;
 IF (SELECT count(*) FROM logistics.governorate WHERE archived_at IS NULL)<>19 OR NOT EXISTS(SELECT 1 FROM logistics.governorate WHERE code='HAL' AND archived_at IS NULL) THEN RAISE EXCEPTION 'Governorate reference set incomplete'; END IF;
 IF (SELECT count(*) FROM payments.provider WHERE archived_at IS NULL AND status='DISABLED')<>7 OR EXISTS(SELECT 1 FROM payments.provider WHERE status<>'DISABLED') THEN RAISE EXCEPTION 'Provider configuration not locked'; END IF;
 PERFORM pg_advisory_xact_lock(hashtextextended('exchi-seed:'||tc,0));
 SELECT id INTO t FROM organizations.tenant WHERE code=tc;
 fresh:=NOT FOUND;
 IF fresh THEN INSERT INTO organizations.tenant(code,name) VALUES(tc,nm) RETURNING id INTO t;
 ELSIF NOT EXISTS(SELECT 1 FROM organizations.tenant WHERE id=t AND name=nm AND status='ACTIVE' AND archived_at IS NULL) THEN RAISE EXCEPTION 'Existing tenant differs; no overwrite'; END IF;
 IF EXISTS(SELECT 1 FROM compliance.policy WHERE tenant_id=t AND status='ACTIVE' AND code IN ('FINANCIAL_POSTING','TRADE_CREDIT','DIGITAL_PAYMENTS')) THEN RAISE EXCEPTION 'Active financial policy; seed refused'; END IF;
 FOR x IN SELECT * FROM (VALUES ('SUPER_ADMIN','command'),('CEO_GM','command'),('FINANCE_CONTROLLER','command'),('WAREHOUSE_MANAGER','command'),('LOGISTICS_DISPATCHER','command'),('REGIONAL_SALES_MANAGER','command'),('COMPLIANCE_OFFICER','command'),('COMMAND_ADMIN','command'),('COMMAND_VIEWER','command'),('RETAILER','retailer'),('WHOLESALER','supplier'),('MANDOOB','field'),('DRIVER','driver')) AS roles(code,aud) LOOP
   IF fresh THEN INSERT INTO "authorization".role(tenant_id,code,name) VALUES(t,x.code,x.code) RETURNING id INTO r;
     INSERT INTO "authorization".role_permission(tenant_id,role_id,permission) VALUES(t,r,'auth.login.'||x.aud);
     IF x.code='RETAILER' THEN INSERT INTO "authorization".role_permission(tenant_id,role_id,permission) VALUES(t,r,'commerce.cart.create'); END IF;
     IF x.code IN ('SUPER_ADMIN','COMMAND_VIEWER') THEN INSERT INTO "authorization".role_permission(tenant_id,role_id,permission) VALUES(t,r,'catalog.brand.read'); END IF;
   ELSE
     SELECT id INTO r FROM "authorization".role WHERE tenant_id=t AND code=x.code AND scope_id IS NULL AND archived_at IS NULL;
     IF NOT FOUND OR NOT EXISTS(SELECT 1 FROM "authorization".role_permission WHERE tenant_id=t AND role_id=r AND permission='auth.login.'||x.aud AND archived_at IS NULL) THEN RAISE EXCEPTION 'Existing role differs; no privilege change: %',x.code; END IF;
   END IF;
 END LOOP;
 SELECT id INTO r FROM "authorization".role WHERE tenant_id=t AND code='SUPER_ADMIN';
 IF fresh THEN
  IF EXISTS(SELECT 1 FROM identity.principal WHERE phone=ph) THEN RAISE EXCEPTION 'Bootstrap identity exists; use independently approved provisioning instead'; END IF;
  INSERT INTO identity.principal(phone,display_name) VALUES(ph,an) RETURNING id INTO p;
  INSERT INTO organizations.membership(tenant_id,principal_id) VALUES(t,p) RETURNING id INTO m;
  INSERT INTO "authorization".assignment(tenant_id,membership_id,role_id) VALUES(t,m,r);
 ELSE
  IF NOT EXISTS(SELECT 1 FROM identity.principal ip JOIN organizations.membership om ON om.principal_id=ip.id JOIN "authorization".assignment aa ON aa.tenant_id=om.tenant_id AND aa.membership_id=om.id WHERE ip.phone=ph AND ip.display_name=an AND ip.status='ACTIVE' AND ip.archived_at IS NULL AND om.tenant_id=t AND om.status='ACTIVE' AND om.archived_at IS NULL AND om.scope_id IS NULL AND aa.role_id=r AND aa.archived_at IS NULL AND aa.assigned_scope_id IS NULL AND (aa.valid_until IS NULL OR aa.valid_until>now())) THEN RAISE EXCEPTION 'Existing bootstrap differs; no promotion'; END IF;
 END IF;
 FOR f IN SELECT * FROM (VALUES ('OFFICIAL',current_setting('exchi.seed.official')::numeric,current_setting('exchi.seed.official_source')),('INDICATIVE',current_setting('exchi.seed.indicative')::numeric,current_setting('exchi.seed.indicative_source'))) AS rates(kind,rate,source) LOOP
  IF f.rate<=0 OR f.rate::text IN ('NaN','Infinity','-Infinity') OR f.rate<>round(f.rate,8) OR length(trim(f.source))<8 THEN RAISE EXCEPTION 'Invalid sourced FX input'; END IF;
  IF f.kind='OFFICIAL' AND f.source !~ '^https://(www\.)?cbi\.iq/' AND current_database()<>'wholesale_test' THEN RAISE EXCEPTION 'Official rate must cite CBI'; END IF;
  IF EXISTS(SELECT 1 FROM treasury.fx_rate WHERE tenant_id=t AND kind=f.kind AND base_currency='USD' AND quote_currency='IQD' AND effective_from=eff) THEN
    IF NOT EXISTS(SELECT 1 FROM treasury.fx_rate WHERE tenant_id=t AND kind=f.kind AND base_currency='USD' AND quote_currency='IQD' AND effective_from=eff AND rate=f.rate AND source_ref=f.source AND status='DRAFT' AND archived_at IS NULL) THEN RAISE EXCEPTION 'FX seed conflicts with existing rate'; END IF;
  ELSE INSERT INTO treasury.fx_rate(tenant_id,kind,base_currency,quote_currency,rate,source_ref,effective_from,status) VALUES(t,f.kind,'USD','IQD',f.rate,f.source,eff,'DRAFT'); END IF;
 END LOOP;
END $$;
COMMIT;
