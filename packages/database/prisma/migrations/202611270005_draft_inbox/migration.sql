BEGIN;
-- Non-binding retailer procurement drafts only. No order/stock/credit/payment effect.
ALTER TABLE integrations.sync_operation ADD COLUMN payload jsonb;
CREATE FUNCTION app_private.receive_retailer_draft(t uuid,s uuid,k uuid,lines jsonb)
RETURNS TABLE(receipt_id uuid,state text) LANGUAGE plpgsql SECURITY DEFINER SET search_path=pg_catalog,pg_temp AS $$
DECLARE actor_id uuid:=app_private.actor(); key_arg text:='retailer-draft:'||k::text; h text; saved integrations.sync_operation%ROWTYPE; x jsonb;
BEGIN
 PERFORM app_private.require_permission(t,s,'commerce.cart.create');
 IF s IS NULL OR actor_id IS NULL OR k IS NULL THEN RAISE EXCEPTION 'draft scope required' USING ERRCODE='42501'; END IF;
 IF NOT EXISTS(SELECT 1 FROM organizations.scope sc JOIN organizations.party p ON p.tenant_id=sc.tenant_id AND p.scope_id=sc.id JOIN organizations.party_member pm ON pm.tenant_id=p.tenant_id AND pm.party_id=p.id WHERE sc.tenant_id=t AND sc.id=s AND sc.kind='RETAILER' AND sc.archived_at IS NULL AND p.kind='RETAILER' AND p.status='ACTIVE' AND p.archived_at IS NULL AND pm.membership_id=actor_id AND pm.archived_at IS NULL AND (pm.delegation_expires IS NULL OR pm.delegation_expires>now())) THEN RAISE EXCEPTION 'retailer delegation required' USING ERRCODE='42501'; END IF;
 IF lines IS NULL OR jsonb_typeof(lines)<>'array' THEN RAISE EXCEPTION 'invalid draft' USING ERRCODE='22023'; END IF;
 IF jsonb_array_length(lines) NOT BETWEEN 1 AND 250 OR octet_length(lines::text)>65536 THEN RAISE EXCEPTION 'invalid draft size' USING ERRCODE='22023'; END IF;
 FOR x IN SELECT value FROM jsonb_array_elements(lines) LOOP
  IF jsonb_typeof(x)<>'object' THEN RAISE EXCEPTION 'invalid draft line' USING ERRCODE='22023'; END IF;
  IF NOT (x ? 'sku' AND x ? 'cartons') OR (x-'sku'-'cartons')<>'{}'::jsonb OR jsonb_typeof(x->'sku')<>'string' OR char_length(x->>'sku') NOT BETWEEN 1 AND 80 OR jsonb_typeof(x->'cartons')<>'number' OR (x->>'cartons') !~ '^[1-9][0-9]{0,5}$' THEN RAISE EXCEPTION 'invalid draft line' USING ERRCODE='22023'; END IF;
  IF (x->>'cartons')::numeric>100000 THEN RAISE EXCEPTION 'invalid draft quantity' USING ERRCODE='22023'; END IF;
 END LOOP;
 IF (SELECT count(DISTINCT lower(v->>'sku')) FROM jsonb_array_elements(lines) a(v))<>jsonb_array_length(lines) THEN RAISE EXCEPTION 'duplicate draft SKU' USING ERRCODE='22023'; END IF;
 h:=encode(public.digest(convert_to(lines::text,'UTF8'),'sha256'),'hex');
 INSERT INTO integrations.sync_operation(tenant_id,scope_id,membership_id,client_key,payload_hash,payload,status)
 VALUES(t,s,actor_id,key_arg,h,lines,'REQUOTE_REQUIRED') ON CONFLICT(tenant_id,membership_id,client_key) DO NOTHING;
 SELECT * INTO STRICT saved FROM integrations.sync_operation WHERE tenant_id=t AND membership_id=actor_id AND client_key=key_arg FOR UPDATE;
 IF saved.scope_id IS DISTINCT FROM s OR saved.payload_hash<>h OR saved.payload IS DISTINCT FROM lines OR saved.archived_at IS NOT NULL THEN RAISE EXCEPTION 'draft replay conflict' USING ERRCODE='23505'; END IF;
 RETURN QUERY SELECT saved.id,saved.status;
END $$;
REVOKE ALL ON FUNCTION app_private.receive_retailer_draft(uuid,uuid,uuid,jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION app_private.receive_retailer_draft(uuid,uuid,uuid,jsonb) TO wholesale_runtime;
COMMIT;
