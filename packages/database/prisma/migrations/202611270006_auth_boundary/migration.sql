BEGIN;
-- Existing migrations and financial feature gates are untouched.
ALTER TABLE identity.otp_challenge ADD COLUMN tenant_code text, ADD COLUMN audience text;
ALTER TABLE identity.session ADD COLUMN mfa_at timestamptz;
ALTER TABLE identity.principal ADD COLUMN last_totp_step bigint;
CREATE INDEX otp_phone_created_idx ON identity.otp_challenge(phone,created_at DESC);
CREATE INDEX otp_created_idx ON identity.otp_challenge(created_at);
CREATE OR REPLACE FUNCTION app_private.can(t uuid, s uuid, p text) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog,pg_temp AS $$
 SELECT t=app_private.tenant() AND EXISTS (
  SELECT 1 FROM organizations.membership m JOIN identity.principal u ON u.id=m.principal_id
  JOIN organizations.tenant te ON te.id=m.tenant_id
  JOIN "authorization".assignment a ON a.tenant_id=m.tenant_id AND a.membership_id=m.id
  JOIN "authorization".role r ON r.tenant_id=a.tenant_id AND r.id=a.role_id
  JOIN "authorization".role_permission rp ON rp.tenant_id=r.tenant_id AND rp.role_id=r.id
  WHERE m.tenant_id=t AND m.id=app_private.actor() AND m.status='ACTIVE' AND m.archived_at IS NULL
  AND u.status='ACTIVE' AND u.archived_at IS NULL AND te.status='ACTIVE' AND te.archived_at IS NULL
  AND a.archived_at IS NULL AND r.archived_at IS NULL AND rp.archived_at IS NULL
  AND (a.valid_until IS NULL OR a.valid_until>now()) AND rp.permission=p
  AND (nullif(current_setting('app.audience',true),'') IS NULL OR EXISTS(
    SELECT 1 FROM "authorization".role_permission ap WHERE ap.tenant_id=r.tenant_id AND ap.role_id=r.id AND ap.archived_at IS NULL AND ap.permission='auth.login.'||current_setting('app.audience',true)))
  AND (a.assigned_scope_id IS NULL OR (s IS NOT NULL AND a.assigned_scope_id=s AND EXISTS
      (SELECT 1 FROM organizations.scope x WHERE x.tenant_id=t AND x.id=s AND x.archived_at IS NULL)))
 )
$$;

-- The API is a trusted issuer; raw SQL access is never given to a browser.
CREATE FUNCTION app_private.login_allowed(t uuid,m uuid,s uuid,aud text) RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog,pg_temp AS $$
 SELECT EXISTS(SELECT 1 FROM organizations.membership mm JOIN organizations.tenant tt ON tt.id=mm.tenant_id
 JOIN identity.principal pp ON pp.id=mm.principal_id
 JOIN "authorization".assignment aa ON aa.tenant_id=mm.tenant_id AND aa.membership_id=mm.id
 JOIN "authorization".role rr ON rr.tenant_id=aa.tenant_id AND rr.id=aa.role_id
 JOIN "authorization".role_permission rp ON rp.tenant_id=rr.tenant_id AND rp.role_id=rr.id
 WHERE mm.tenant_id=t AND mm.id=m AND mm.scope_id IS NOT DISTINCT FROM s
 AND mm.archived_at IS NULL AND mm.status='ACTIVE' AND tt.archived_at IS NULL AND tt.status='ACTIVE'
 AND pp.archived_at IS NULL AND pp.status='ACTIVE' AND aa.archived_at IS NULL AND rr.archived_at IS NULL AND rp.archived_at IS NULL
 AND (aa.valid_until IS NULL OR aa.valid_until>now()) AND (aa.assigned_scope_id IS NULL OR aa.assigned_scope_id=s)
 AND rp.permission='auth.login.'||aud AND aud IN ('retailer','supplier','field','driver','command')
 AND (s IS NULL OR EXISTS(SELECT 1 FROM organizations.scope sc WHERE sc.tenant_id=t AND sc.id=s AND sc.archived_at IS NULL))
 AND (aud NOT IN ('retailer','supplier') OR EXISTS(SELECT 1 FROM organizations.party_member pm JOIN organizations.party p ON p.tenant_id=pm.tenant_id AND p.id=pm.party_id WHERE pm.tenant_id=t AND pm.membership_id=m AND pm.archived_at IS NULL AND (pm.delegation_expires IS NULL OR pm.delegation_expires>now()) AND p.scope_id=s AND p.archived_at IS NULL AND ((aud='retailer' AND p.kind='RETAILER' AND p.status IN ('PENDING','ACTIVE')) OR (aud='supplier' AND p.kind='SUPPLIER' AND p.status='ACTIVE' AND EXISTS(SELECT 1 FROM organizations.supplier_profile sp WHERE sp.tenant_id=t AND sp.party_id=p.id AND sp.archived_at IS NULL AND sp.status='APPROVED')))))
 )
$$;
CREATE FUNCTION app_private.begin_otp(cid uuid,ph text,tc text,aud text,dig text,ch text) RETURNS boolean
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,pg_temp AS $$
BEGIN
 IF ph IS NULL OR tc IS NULL OR aud IS NULL OR dig IS NULL OR ch IS NULL OR ph !~ '^\+9647[0-9]{9}$' OR tc !~ '^[A-Za-z0-9_-]{1,64}$' OR aud NOT IN ('retailer','supplier','field','driver','command') OR dig !~ '^[0-9a-f]{64}$' OR ch NOT IN ('WHATSAPP','SMS','DEV') THEN RETURN false; END IF;
 -- Global admission budget plus cross-audience, per-phone cooldown; no IP supplied by a browser is trusted.
 PERFORM pg_advisory_xact_lock(68503001);
 IF (SELECT count(*) FROM identity.otp_challenge WHERE created_at>clock_timestamp()-interval '1 minute')>=300 OR EXISTS(SELECT 1 FROM identity.otp_challenge WHERE phone=ph AND created_at>clock_timestamp()-interval '60 seconds') OR (SELECT count(*) FROM identity.otp_challenge WHERE phone=ph AND created_at>clock_timestamp()-interval '1 hour')>=5 THEN RETURN false; END IF;
 UPDATE identity.otp_challenge SET consumed_at=clock_timestamp() WHERE phone=ph AND consumed_at IS NULL;
 INSERT INTO identity.otp_challenge(id,phone,tenant_code,audience,challenge_digest,channel,expires_at) VALUES(cid,ph,tc,aud,dig,ch,clock_timestamp()+interval '5 minutes');
 RETURN true;
END $$;
CREATE FUNCTION app_private.invalidate_otp(cid uuid) RETURNS void LANGUAGE sql SECURITY DEFINER SET search_path=pg_catalog,pg_temp AS $$ UPDATE identity.otp_challenge SET consumed_at=clock_timestamp() WHERE id=cid AND consumed_at IS NULL $$;
CREATE FUNCTION app_private.finish_otp(cid uuid,ph text,tc text,aud text,dig text,token_hash text,mfa_step bigint,allow_signup boolean) RETURNS boolean
LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,pg_temp AS $$
DECLARE c identity.otp_challenge%ROWTYPE; t uuid; p uuid; m uuid; s uuid; party_id_arg uuid; role_id_arg uuid;
BEGIN
 SELECT * INTO c FROM identity.otp_challenge WHERE id=cid FOR UPDATE;
 IF NOT FOUND OR c.consumed_at IS NOT NULL OR c.archived_at IS NOT NULL OR c.expires_at<=clock_timestamp() OR c.attempts>=5 THEN RETURN false; END IF;
 UPDATE identity.otp_challenge SET attempts=attempts+1,consumed_at=CASE WHEN attempts+1>=5 THEN clock_timestamp() ELSE NULL END WHERE id=cid;
 IF c.phone IS DISTINCT FROM ph OR c.tenant_code IS DISTINCT FROM tc OR c.audience IS DISTINCT FROM aud OR c.challenge_digest IS DISTINCT FROM dig OR token_hash IS NULL OR token_hash !~ '^[0-9a-f]{64}$' THEN RETURN false; END IF;
 IF aud<>'retailer' AND (mfa_step IS NULL OR abs(mfa_step-floor(extract(epoch FROM clock_timestamp())/30)::bigint)>1) THEN RETURN false; END IF;
 SELECT id INTO t FROM organizations.tenant WHERE code=tc AND status='ACTIVE' AND archived_at IS NULL;
 IF t IS NULL THEN RETURN false; END IF;
 -- Serialize identity creation, including across tenants.
 PERFORM pg_advisory_xact_lock(hashtextextended(ph,68503002));
 SELECT id INTO p FROM identity.principal WHERE phone=ph AND status='ACTIVE' AND archived_at IS NULL;
 IF p IS NULL AND EXISTS(SELECT 1 FROM identity.principal WHERE phone=ph) THEN RETURN false; END IF;
 IF p IS NOT NULL THEN SELECT id,scope_id INTO m,s FROM organizations.membership WHERE tenant_id=t AND principal_id=p; END IF;
 IF m IS NULL THEN
  IF aud<>'retailer' OR NOT coalesce(allow_signup,false) THEN RETURN false; END IF;
  SELECT r.id INTO role_id_arg FROM "authorization".role r JOIN "authorization".role_permission rp ON rp.tenant_id=r.tenant_id AND rp.role_id=r.id WHERE r.tenant_id=t AND r.code='RETAILER' AND r.scope_id IS NULL AND r.archived_at IS NULL AND rp.archived_at IS NULL AND rp.permission='auth.login.retailer';
  IF role_id_arg IS NULL THEN RETURN false; END IF;
  IF p IS NULL THEN INSERT INTO identity.principal(phone,display_name) VALUES(ph,'New retailer') RETURNING id INTO p; END IF;
  INSERT INTO organizations.scope(tenant_id,code,kind,name) VALUES(t,'retail-'||cid,'RETAILER','Unverified storefront') RETURNING id INTO s;
  INSERT INTO organizations.membership(tenant_id,scope_id,principal_id) VALUES(t,s,p) RETURNING id INTO m;
  PERFORM set_config('app.tenant_id',t::text,true); PERFORM set_config('app.membership_id',m::text,true);
  INSERT INTO organizations.party(tenant_id,scope_id,kind,code,name_en) VALUES(t,s,'RETAILER','retail-'||cid,'Unverified storefront') RETURNING id INTO party_id_arg;
  INSERT INTO organizations.party_member(tenant_id,scope_id,party_id,membership_id,job_role) VALUES(t,s,party_id_arg,m,'OWNER');
  INSERT INTO organizations.retailer_profile(tenant_id,scope_id,party_id,vertical) VALUES(t,s,party_id_arg,'UNSPECIFIED');
  INSERT INTO compliance.kyc_case(tenant_id,scope_id,party_id,status) VALUES(t,s,party_id_arg,'PHONE_VERIFIED');
  INSERT INTO "authorization".assignment(tenant_id,scope_id,membership_id,role_id,assigned_scope_id) VALUES(t,s,m,role_id_arg,s);
 END IF;
 IF NOT app_private.login_allowed(t,m,s,aud) THEN RETURN false; END IF;
 IF aud<>'retailer' THEN
  UPDATE identity.principal SET last_totp_step=mfa_step WHERE id=p AND (last_totp_step IS NULL OR last_totp_step<mfa_step);
  IF NOT FOUND THEN RETURN false; END IF;
 END IF;
 PERFORM set_config('app.tenant_id',t::text,true); PERFORM set_config('app.membership_id',m::text,true);
 UPDATE identity.otp_challenge SET consumed_at=clock_timestamp() WHERE id=cid;
 -- Rotate all prior tokens for the same application; other audiences remain independent.
 UPDATE identity.session SET revoked_at=clock_timestamp() WHERE tenant_id=t AND membership_id=m AND audience=aud AND revoked_at IS NULL;
 INSERT INTO identity.session(tenant_id,scope_id,membership_id,token_digest,audience,expires_at,mfa_at) VALUES(t,s,m,token_hash,aud,clock_timestamp()+CASE WHEN aud='retailer' THEN interval '24 hours' ELSE interval '8 hours' END,CASE WHEN aud<>'retailer' THEN clock_timestamp() ELSE NULL END);
 RETURN true;
END $$;
-- Legacy resolver remains internal for previous tests; the HTTP boundary exclusively uses this stricter resolver.
CREATE FUNCTION app_private.resolve_login(dig text,aud text) RETURNS TABLE(tenant_id uuid,membership_id uuid,scope_id uuid,audience text)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog,pg_temp AS $$
 SELECT x.tenant_id,x.membership_id,x.scope_id,x.audience FROM app_private.resolve_session(dig,aud) x JOIN identity.session ss ON ss.token_digest=dig
 WHERE app_private.login_allowed(x.tenant_id,x.membership_id,x.scope_id,aud) AND (aud='retailer' OR (ss.mfa_at IS NOT NULL AND ss.mfa_at>now()-interval '8 hours'))
$$;
CREATE FUNCTION app_private.logout_login(dig text,aud text) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,pg_temp AS $$
DECLARE s identity.session%ROWTYPE; BEGIN SELECT * INTO s FROM identity.session WHERE token_digest=dig AND audience=aud AND revoked_at IS NULL FOR UPDATE; IF FOUND THEN PERFORM set_config('app.tenant_id',s.tenant_id::text,true); PERFORM set_config('app.membership_id',s.membership_id::text,true); UPDATE identity.session SET revoked_at=clock_timestamp() WHERE id=s.id; END IF; END $$;
-- Fail closed: both current case and retailer profile must be approved; no preview tier.
CREATE FUNCTION app_private.retail_entitlement(t uuid,m uuid,s uuid) RETURNS TABLE(kyc_status text,tier text,can_price boolean)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog,pg_temp AS $$
 SELECT coalesce(k.status,'PENDING'),r.tier,coalesce(p.status='ACTIVE' AND r.kyc_status='APPROVED' AND k.status='APPROVED' AND k.archived_at IS NULL AND k.decided_by IS NOT NULL AND k.decided_at IS NOT NULL AND r.tier IN ('STANDARD','SILVER','GOLD','VIP') AND EXISTS(SELECT 1 FROM compliance.kyc_decision kd WHERE kd.tenant_id=t AND kd.case_id=k.id AND kd.reviewer_id=k.decided_by AND kd.outcome='APPROVED' AND kd.archived_at IS NULL),false)
 FROM organizations.party p JOIN organizations.party_member pm ON pm.tenant_id=p.tenant_id AND pm.party_id=p.id JOIN organizations.retailer_profile r ON r.tenant_id=p.tenant_id AND r.party_id=p.id
 LEFT JOIN LATERAL (SELECT kc.id,kc.status,kc.decided_by,kc.decided_at,kc.archived_at FROM compliance.kyc_case kc WHERE kc.tenant_id=t AND kc.party_id=p.id ORDER BY kc.created_at DESC,kc.id DESC LIMIT 1) k ON true
 WHERE t=app_private.tenant() AND m=app_private.actor() AND app_private.login_allowed(t,m,s,'retailer') AND p.tenant_id=t AND p.scope_id=s AND p.kind='RETAILER' AND p.archived_at IS NULL AND pm.membership_id=m AND pm.archived_at IS NULL AND (pm.delegation_expires IS NULL OR pm.delegation_expires>now()) AND r.archived_at IS NULL AND r.scope_id=s AND pm.scope_id=s
$$;
-- Preview only contains globally published, non-regulated catalog entries. Approved customers see exact-tier IQD price rules only.
CREATE FUNCTION app_private.retail_catalog(t uuid,m uuid,s uuid) RETURNS SETOF jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=pg_catalog,pg_temp AS $$
DECLARE ent record; BEGIN
 SELECT * INTO ent FROM app_private.retail_entitlement(t,m,s); IF NOT FOUND THEN RAISE EXCEPTION 'retailer entitlement missing' USING ERRCODE='42501'; END IF;
 RETURN QUERY SELECT jsonb_build_object('id',p.id,'sku',p.sku,'name_en',p.name_en,'name_ar',p.name_ar,'name_ku',p.name_ku) || CASE WHEN ent.can_price THEN jsonb_build_object('price_rules',coalesce((SELECT jsonb_agg(jsonb_build_object('offer_id',o.id,'uom',u.code,'min_qty',pr.min_qty::text,'amount',pr.amount::text,'currency',pr.currency) ORDER BY o.id,pr.min_qty) FROM pricing.offer o JOIN pricing.price_rule pr ON pr.tenant_id=o.tenant_id AND pr.offer_id=o.id JOIN catalog.uom u ON u.tenant_id=o.tenant_id AND u.id=o.uom_id AND u.product_id=p.id JOIN organizations.party seller ON seller.tenant_id=o.tenant_id AND seller.id=o.seller_id WHERE o.tenant_id=t AND o.product_id=p.id AND o.scope_id IS NULL AND pr.scope_id IS NULL AND o.status='ACTIVE' AND pr.status='ACTIVE' AND o.archived_at IS NULL AND pr.archived_at IS NULL AND u.archived_at IS NULL AND seller.archived_at IS NULL AND seller.status='ACTIVE' AND seller.kind='OPERATOR' AND pr.tier=ent.tier AND pr.currency='IQD' AND pr.effective_from<=now() AND (pr.effective_to IS NULL OR pr.effective_to>now())), '[]'::jsonb)) ELSE '{}'::jsonb END
 FROM catalog.product p JOIN catalog.category ca ON ca.tenant_id=p.tenant_id AND ca.id=p.category_id WHERE p.tenant_id=t AND p.scope_id IS NULL AND p.status='ACTIVE' AND p.archived_at IS NULL AND ca.archived_at IS NULL AND ca.parent_id IS NULL AND NOT ca.regulated ORDER BY p.sku LIMIT 100;
END $$;
REVOKE ALL ON FUNCTION app_private.login_allowed(uuid,uuid,uuid,text),app_private.begin_otp(uuid,text,text,text,text,text),app_private.invalidate_otp(uuid),app_private.finish_otp(uuid,text,text,text,text,text,bigint,boolean),app_private.resolve_login(text,text),app_private.logout_login(text,text),app_private.retail_entitlement(uuid,uuid,uuid),app_private.retail_catalog(uuid,uuid,uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION app_private.begin_otp(uuid,text,text,text,text,text),app_private.invalidate_otp(uuid),app_private.finish_otp(uuid,text,text,text,text,text,bigint,boolean),app_private.resolve_login(text,text),app_private.logout_login(text,text),app_private.retail_entitlement(uuid,uuid,uuid),app_private.retail_catalog(uuid,uuid,uuid) TO wholesale_runtime;
COMMIT;
