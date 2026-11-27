BEGIN;
-- Additive indexes; historical migrations and pricing policies remain unchanged.
CREATE INDEX ix_product_name_en_trgm ON catalog.product USING gin (name_en gin_trgm_ops) WHERE archived_at IS NULL;
CREATE INDEX ix_product_name_ar_trgm ON catalog.product USING gin (name_ar gin_trgm_ops) WHERE archived_at IS NULL;
CREATE INDEX ix_product_name_ku_trgm ON catalog.product USING gin (name_ku gin_trgm_ops) WHERE archived_at IS NULL;
CREATE INDEX ix_product_ingredients ON catalog.product USING gin (ingredients jsonb_path_ops) WHERE archived_at IS NULL;
CREATE INDEX ix_address_landmark_trgm ON logistics.address USING gin (landmark gin_trgm_ops) WHERE archived_at IS NULL;
CREATE INDEX ix_address_neighborhood_trgm ON logistics.address USING gin (neighborhood gin_trgm_ops) WHERE archived_at IS NULL;
CREATE INDEX ix_address_governorate_district ON logistics.address(tenant_id,governorate_id,district_id) WHERE archived_at IS NULL;
COMMIT;
