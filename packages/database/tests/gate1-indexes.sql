\set ON_ERROR_STOP on
DO $$
DECLARE i text;
BEGIN
 FOREACH i IN ARRAY ARRAY['catalog.ix_product_name_en_trgm','catalog.ix_product_name_ar_trgm','catalog.ix_product_name_ku_trgm','catalog.ix_product_ingredients','logistics.ix_address_landmark_trgm','logistics.ix_address_neighborhood_trgm','logistics.ix_address_governorate_district','logistics.ix_address_point','logistics.ix_zone_boundary'] LOOP
  IF NOT EXISTS(SELECT 1 FROM pg_index WHERE indexrelid=to_regclass(i) AND indisvalid AND indisready) THEN RAISE EXCEPTION 'Missing or invalid index: %',i; END IF;
 END LOOP;
 IF EXISTS(SELECT 1 FROM treasury.fx_rate WHERE status='ACTIVE' AND kind='INDICATIVE') THEN RAISE EXCEPTION 'Indicative FX unexpectedly active'; END IF;
END $$;
SELECT 'Gate 1 index checks passed' AS result;
