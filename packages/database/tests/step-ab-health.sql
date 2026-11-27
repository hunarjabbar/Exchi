\set ON_ERROR_STOP on
DO $$ BEGIN
 IF (SELECT count(*) FROM logistics.governorate WHERE archived_at IS NULL)<>19 THEN RAISE EXCEPTION 'governorate seed mismatch'; END IF;
 IF (SELECT count(*) FROM payments.provider WHERE status='DISABLED')<>7 OR EXISTS(SELECT 1 FROM payments.provider WHERE status<>'DISABLED') THEN RAISE EXCEPTION 'provider gate mismatch'; END IF;
 IF EXISTS(SELECT 1 FROM compliance.policy WHERE status='ACTIVE' AND code IN ('FINANCIAL_POSTING','TRADE_CREDIT','DIGITAL_PAYMENTS')) THEN RAISE EXCEPTION 'financial gate unexpectedly active'; END IF;
 IF EXISTS(SELECT 1 FROM pg_roles WHERE rolname IN ('wholesale_runtime','wholesale_stepab_login') AND (rolsuper OR rolbypassrls OR rolcreatedb OR rolcreaterole)) THEN RAISE EXCEPTION 'runtime privilege escalation'; END IF;
 IF NOT EXISTS(SELECT 1 FROM pg_extension WHERE extname='postgis') THEN RAISE EXCEPTION 'PostGIS missing'; END IF;
 IF NOT EXISTS(SELECT 1 FROM organizations.tenant WHERE code='wholesale-local') THEN RAISE EXCEPTION 'fixture missing'; END IF;
END $$;
SELECT version(), public.postgis_full_version();
SELECT count(*) AS governorates FROM logistics.governorate;
SELECT code,status FROM payments.provider ORDER BY code;
