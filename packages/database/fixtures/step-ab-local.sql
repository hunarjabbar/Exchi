\set ON_ERROR_STOP on
BEGIN;
DO $$
DECLARE t uuid; r uuid; s uuid; p uuid; m uuid; py uuid; rolecode text; aud text; phone text; num int; cat uuid; prod uuid; u uuid; seller uuid; offer uuid; reviewer uuid; k uuid; rowdata record;
BEGIN
 IF current_database()<>'wholesale_test' OR current_user<>'postgres' THEN RAISE EXCEPTION 'Disposable local database only'; END IF;
 IF EXISTS(SELECT 1 FROM organizations.tenant WHERE code='wholesale-local') THEN RAISE NOTICE 'local seed already exists; no reset performed'; RETURN; END IF;
 INSERT INTO organizations.tenant(code,name) VALUES('wholesale-local','Synthetic Wholesale local acceptance') RETURNING id INTO t;
 FOR rowdata IN SELECT * FROM (VALUES ('RETAILER','retailer'),('MANDOOB','field'),('WHOLESALER','supplier'),('COMMAND_ADMIN','command'),('DRIVER','driver'),('COMMAND_VIEWER','command')) AS roles(code,audience) LOOP
  INSERT INTO "authorization".role(tenant_id,code,name) VALUES(t,rowdata.code,rowdata.code) RETURNING id INTO r;
  INSERT INTO "authorization".role_permission(tenant_id,role_id,permission) VALUES(t,r,'auth.login.'||rowdata.audience);
  IF rowdata.code='RETAILER' THEN INSERT INTO "authorization".role_permission(tenant_id,role_id,permission) VALUES(t,r,'commerce.cart.create'); END IF;
  IF rowdata.code='COMMAND_ADMIN' THEN
   INSERT INTO "authorization".role_permission(tenant_id,role_id,permission) SELECT t,r,'catalog.'||resource||'.'||action FROM unnest(ARRAY['brand','category','product']) resource CROSS JOIN unnest(ARRAY['read','create','update']) action;
  END IF;
  IF rowdata.code='COMMAND_VIEWER' THEN INSERT INTO "authorization".role_permission(tenant_id,role_id,permission) VALUES(t,r,'catalog.brand.read'); END IF;
 END LOOP;
 -- Staff accounts are pre-provisioned, never self-registered. Synthetic numbers never receive external messages in dev mode.
 FOR num IN 2..8 LOOP
  phone:='+96475000000'||lpad(num::text,2,'0');
  rolecode:=CASE num WHEN 2 THEN 'RETAILER' WHEN 3 THEN 'COMMAND_ADMIN' WHEN 4 THEN 'MANDOOB' WHEN 5 THEN 'WHOLESALER' WHEN 6 THEN 'DRIVER' WHEN 7 THEN 'COMMAND_VIEWER' ELSE 'COMMAND_ADMIN' END;
  SELECT id INTO r FROM "authorization".role WHERE tenant_id=t AND code=rolecode;
  s:=NULL;
  IF num IN (2,4,5,6) THEN INSERT INTO organizations.scope(tenant_id,code,kind,name) VALUES(t,'fixture-'||num,CASE num WHEN 2 THEN 'RETAILER' WHEN 5 THEN 'SUPPLIER' ELSE 'TERRITORY' END,'Synthetic scope') RETURNING id INTO s; END IF;
  INSERT INTO identity.principal(phone,display_name) VALUES(phone,'Synthetic account '||num) RETURNING id INTO p;
  INSERT INTO organizations.membership(tenant_id,scope_id,principal_id) VALUES(t,s,p) RETURNING id INTO m;
  INSERT INTO "authorization".assignment(tenant_id,scope_id,membership_id,role_id,assigned_scope_id) VALUES(t,s,m,r,s);
  IF num=3 THEN reviewer:=m; END IF;
  IF num IN (2,5) THEN
   INSERT INTO organizations.party(tenant_id,scope_id,kind,code,name_en,status) VALUES(t,s,CASE WHEN num=2 THEN 'RETAILER' ELSE 'SUPPLIER' END,'fixture-party-'||num,'Synthetic commercial party','ACTIVE') RETURNING id INTO py;
   INSERT INTO organizations.party_member(tenant_id,scope_id,party_id,membership_id,job_role) VALUES(t,s,py,m,'OWNER');
   IF num=2 THEN INSERT INTO organizations.retailer_profile(tenant_id,scope_id,party_id,vertical,tier,kyc_status) VALUES(t,s,py,'MINIMARKET','STANDARD','APPROVED'); INSERT INTO compliance.kyc_case(tenant_id,scope_id,party_id,status) VALUES(t,s,py,'UNDER_REVIEW') RETURNING id INTO k;
   ELSE INSERT INTO organizations.supplier_profile(tenant_id,scope_id,party_id,status) VALUES(t,s,py,'APPROVED'); END IF;
  END IF;
 END LOOP;
 UPDATE compliance.kyc_case SET status='APPROVED',decided_by=reviewer,decided_at=now() WHERE id=k;
 INSERT INTO compliance.kyc_decision(tenant_id,scope_id,case_id,reviewer_id,outcome,reason,evidence) SELECT t,scope_id,k,reviewer,'APPROVED','Synthetic disposable test only','{}'::jsonb FROM compliance.kyc_case WHERE id=k;
 INSERT INTO organizations.party(tenant_id,kind,code,name_en,status) VALUES(t,'OPERATOR','fixture-operator','Synthetic seller','ACTIVE') RETURNING id INTO seller;
 INSERT INTO catalog.category(tenant_id,code,name_en,name_ar,name_ku) VALUES(t,'FIXTURE-CAT','Synthetic category','فئة تجريبية','پۆلی تاقیکردنەوە') RETURNING id INTO cat;
 INSERT INTO catalog.product(tenant_id,category_id,sku,name_en,name_ar,name_ku,status) VALUES(t,cat,'FIXTURE-001','Synthetic product','منتج تجريبي','کاڵای تاقیکردنەوە','ACTIVE') RETURNING id INTO prod;
 INSERT INTO catalog.uom(tenant_id,product_id,code,base_factor) VALUES(t,prod,'CARTON',24) RETURNING id INTO u;
 INSERT INTO pricing.offer(tenant_id,seller_id,product_id,uom_id,status) VALUES(t,seller,prod,u,'ACTIVE') RETURNING id INTO offer;
 INSERT INTO pricing.price_rule(tenant_id,offer_id,tier,min_qty,amount,currency,effective_from,status) VALUES(t,offer,'STANDARD',1,24000,'IQD',now()-interval '1 day','ACTIVE'),(t,offer,'VIP',1,12000,'IQD',now()-interval '1 day','ACTIVE');
 -- Separate tenant contains a sentinel; it must not appear in the first tenant's catalog.
 INSERT INTO organizations.tenant(code,name) VALUES('wholesale-local-other','Synthetic isolation tenant') RETURNING id INTO t;
 INSERT INTO catalog.category(tenant_id,code,name_en,name_ar,name_ku) VALUES(t,'OTHER-CAT','Other category','أخرى','تر') RETURNING id INTO cat;
 INSERT INTO catalog.product(tenant_id,category_id,sku,name_en,name_ar,name_ku,status) VALUES(t,cat,'OTHER-TENANT-SECRET','Other product','آخر','تر','ACTIVE');
END $$;
COMMIT;
