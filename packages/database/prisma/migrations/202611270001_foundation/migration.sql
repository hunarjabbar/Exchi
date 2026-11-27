BEGIN;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE SCHEMA IF NOT EXISTS app_private;
CREATE SCHEMA IF NOT EXISTS accounting;
CREATE SCHEMA IF NOT EXISTS analytics;
CREATE SCHEMA IF NOT EXISTS audit;
CREATE SCHEMA IF NOT EXISTS "authorization";
CREATE SCHEMA IF NOT EXISTS catalog;
CREATE SCHEMA IF NOT EXISTS commerce;
CREATE SCHEMA IF NOT EXISTS compliance;
CREATE SCHEMA IF NOT EXISTS credit;
CREATE SCHEMA IF NOT EXISTS fulfillment;
CREATE SCHEMA IF NOT EXISTS identity;
CREATE SCHEMA IF NOT EXISTS integrations;
CREATE SCHEMA IF NOT EXISTS inventory;
CREATE SCHEMA IF NOT EXISTS logistics;
CREATE SCHEMA IF NOT EXISTS notifications;
CREATE SCHEMA IF NOT EXISTS organizations;
CREATE SCHEMA IF NOT EXISTS payments;
CREATE SCHEMA IF NOT EXISTS pricing;
CREATE SCHEMA IF NOT EXISTS procurement;
CREATE SCHEMA IF NOT EXISTS "returns";
CREATE SCHEMA IF NOT EXISTS treasury;
CREATE TABLE organizations.tenant (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  code text NOT NULL,
  name text NOT NULL,
  status text NOT NULL DEFAULT 'ACTIVE',
  UNIQUE (code)
);
CREATE TABLE identity.principal (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  phone text NOT NULL,
  display_name text NOT NULL,
  status text NOT NULL DEFAULT 'ACTIVE',
  UNIQUE (phone),
  CHECK (phone ~ '^\+964[0-9]{10}$')
);
CREATE TABLE organizations.scope (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  code text NOT NULL,
  kind text NOT NULL,
  parent_id uuid,
  name text NOT NULL,
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,code),
  CHECK (kind IN ('TENANT','BRANCH','WAREHOUSE','TERRITORY','RETAILER','SUPPLIER'))
);
CREATE TABLE organizations.membership (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  principal_id uuid NOT NULL,
  status text NOT NULL DEFAULT 'ACTIVE',
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,principal_id)
);
CREATE TABLE "authorization".role (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  code text NOT NULL,
  name text NOT NULL,
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,code)
);
CREATE TABLE "authorization".role_permission (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  role_id uuid NOT NULL,
  permission text NOT NULL,
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,role_id,permission)
);
CREATE TABLE "authorization".assignment (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  membership_id uuid NOT NULL,
  role_id uuid NOT NULL,
  assigned_scope_id uuid,
  valid_until timestamptz,
  UNIQUE (tenant_id,id)
);
CREATE TABLE identity.device (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  membership_id uuid NOT NULL,
  credential_id text NOT NULL,
  public_key text NOT NULL,
  revoked_at timestamptz,
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,credential_id)
);
CREATE TABLE identity.session (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  membership_id uuid NOT NULL,
  device_id uuid,
  token_digest text NOT NULL,
  audience text NOT NULL,
  expires_at timestamptz NOT NULL,
  revoked_at timestamptz,
  UNIQUE (tenant_id,id),
  UNIQUE (token_digest)
);
CREATE TABLE identity.otp_challenge (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  phone text NOT NULL,
  challenge_digest text NOT NULL,
  channel text NOT NULL,
  expires_at timestamptz NOT NULL,
  attempts integer NOT NULL DEFAULT 0,
  consumed_at timestamptz,
  CHECK (attempts BETWEEN 0 AND 5)
);
CREATE TABLE logistics.governorate (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  code text NOT NULL,
  name_en text NOT NULL,
  name_ar text NOT NULL,
  name_ku text NOT NULL,
  source_url text NOT NULL,
  ku_reviewed boolean NOT NULL DEFAULT false,
  UNIQUE (code)
);
CREATE TABLE logistics.district (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  governorate_id uuid NOT NULL,
  code text NOT NULL,
  name_en text NOT NULL,
  name_ar text NOT NULL,
  name_ku text NOT NULL,
  source_url text NOT NULL,
  UNIQUE (governorate_id,code)
);
CREATE TABLE logistics.zone (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  code text NOT NULL,
  governorate_id uuid NOT NULL,
  name text NOT NULL,
  status text NOT NULL DEFAULT 'QUOTATION_ONLY',
  boundary geography(MultiPolygon,4326),
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,code)
);
CREATE TABLE logistics.address (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  governorate_id uuid NOT NULL,
  district_id uuid,
  neighborhood text NOT NULL,
  landmark text NOT NULL,
  shop_name text NOT NULL,
  point geography(Point,4326),
  accuracy_m numeric(24,8),
  verified_at timestamptz,
  UNIQUE (tenant_id,id),
  CHECK (accuracy_m IS NULL OR accuracy_m >= 0)
);
CREATE TABLE logistics.shipping_tariff (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  zone_id uuid NOT NULL,
  origin_zone_id uuid,
  min_order bigint NOT NULL DEFAULT 0,
  base_fee bigint NOT NULL,
  per_kg numeric(24,8) NOT NULL DEFAULT 0,
  transit_buffer_min integer NOT NULL DEFAULT 0,
  cold_chain boolean NOT NULL DEFAULT false,
  effective_from timestamptz NOT NULL,
  effective_to timestamptz,
  UNIQUE (tenant_id,id),
  CHECK (min_order>=0 AND base_fee>=0 AND per_kg>=0 AND transit_buffer_min>=0),
  CHECK (effective_to IS NULL OR effective_to>effective_from)
);
CREATE TABLE organizations.party (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  kind text NOT NULL,
  code text NOT NULL,
  name_en text NOT NULL,
  name_ar text,
  name_ku text,
  tax_id text,
  registration_no text,
  status text NOT NULL DEFAULT 'PENDING',
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,code),
  CHECK (kind IN ('RETAILER','SUPPLIER','OPERATOR','COURIER'))
);
CREATE TABLE organizations.branch (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  party_id uuid NOT NULL,
  code text NOT NULL,
  name text NOT NULL,
  address_id uuid,
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,party_id,code)
);
CREATE TABLE organizations.party_member (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  party_id uuid NOT NULL,
  membership_id uuid NOT NULL,
  job_role text NOT NULL,
  daily_limit bigint,
  delegation_expires timestamptz,
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,party_id,membership_id),
  CHECK (daily_limit IS NULL OR daily_limit>=0)
);
CREATE TABLE organizations.territory (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  code text NOT NULL,
  name text NOT NULL,
  zone_id uuid NOT NULL,
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,code)
);
CREATE TABLE organizations.field_assignment (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  membership_id uuid NOT NULL,
  territory_id uuid NOT NULL,
  collection_limit bigint NOT NULL DEFAULT 0,
  discount_bps integer NOT NULL DEFAULT 0,
  valid_until timestamptz,
  UNIQUE (tenant_id,id),
  CHECK (collection_limit>=0 AND discount_bps BETWEEN 0 AND 10000)
);
CREATE TABLE organizations.retailer_profile (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  party_id uuid NOT NULL,
  vertical text NOT NULL,
  tier text NOT NULL DEFAULT 'PREVIEW',
  kyc_status text NOT NULL DEFAULT 'PENDING',
  address_id uuid,
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,party_id),
  CHECK (tier IN ('PREVIEW','STANDARD','SILVER','GOLD','VIP'))
);
CREATE TABLE organizations.supplier_profile (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  party_id uuid NOT NULL,
  contract_ref text,
  approved_categories jsonb,
  status text NOT NULL DEFAULT 'PENDING',
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,party_id)
);
CREATE TABLE compliance.kyc_case (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  party_id uuid NOT NULL,
  status text NOT NULL DEFAULT 'DRAFT',
  submitted_at timestamptz,
  risk_level text,
  decision_reason text,
  decided_by uuid,
  decided_at timestamptz,
  UNIQUE (tenant_id,id),
  CHECK (status IN ('DRAFT','PHONE_VERIFIED','PROFILE_COMPLETED','SUBMITTED','UNDER_REVIEW','MORE_INFO','APPROVED','REJECTED','SUSPENDED','EXPIRED','WITHDRAWN'))
);
CREATE TABLE compliance.document (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  party_id uuid NOT NULL,
  kyc_case_id uuid,
  kind text NOT NULL,
  object_key text NOT NULL,
  sha256 text NOT NULL,
  scan_status text NOT NULL DEFAULT 'PENDING',
  expires_at timestamptz,
  capture_evidence jsonb,
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,object_key)
);
CREATE TABLE compliance.kyc_decision (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  case_id uuid NOT NULL,
  reviewer_id uuid NOT NULL,
  outcome text NOT NULL,
  reason text NOT NULL,
  evidence jsonb NOT NULL,
  UNIQUE (tenant_id,id)
);
CREATE TABLE compliance.risk_case (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  party_id uuid,
  kind text NOT NULL,
  severity text NOT NULL,
  status text NOT NULL DEFAULT 'OPEN',
  evidence jsonb NOT NULL,
  UNIQUE (tenant_id,id)
);
CREATE TABLE compliance.policy (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  code text NOT NULL,
  jurisdiction text NOT NULL,
  source_ref text NOT NULL,
  effective_from timestamptz NOT NULL,
  effective_to timestamptz,
  configuration jsonb NOT NULL,
  status text NOT NULL DEFAULT 'DRAFT',
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,code,effective_from),
  CHECK (effective_to IS NULL OR effective_to>effective_from)
);
CREATE TABLE compliance.approval (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  resource_type text NOT NULL,
  resource_id uuid NOT NULL,
  action text NOT NULL,
  payload_hash text NOT NULL,
  maker_id uuid NOT NULL,
  checker_id uuid,
  status text NOT NULL DEFAULT 'PENDING',
  expires_at timestamptz,
  UNIQUE (tenant_id,id),
  CHECK (checker_id IS NULL OR checker_id<>maker_id),
  CHECK (status IN ('PENDING','APPROVED','REJECTED','CONSUMED'))
);
CREATE TABLE catalog.brand (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  code text NOT NULL,
  name_en text NOT NULL,
  name_ar text,
  name_ku text,
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,code)
);
CREATE TABLE catalog.category (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  code text NOT NULL,
  parent_id uuid,
  name_en text NOT NULL,
  name_ar text NOT NULL,
  name_ku text NOT NULL,
  regulated boolean NOT NULL DEFAULT false,
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,code)
);
CREATE TABLE catalog.product (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  sku text NOT NULL,
  brand_id uuid,
  category_id uuid NOT NULL,
  name_en text NOT NULL,
  name_ar text NOT NULL,
  name_ku text NOT NULL,
  ingredients jsonb,
  search_text text NOT NULL DEFAULT '',
  status text NOT NULL DEFAULT 'DRAFT',
  cold_chain boolean NOT NULL DEFAULT false,
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,sku)
);
CREATE TABLE catalog.product_alias (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  product_id uuid NOT NULL,
  locale text NOT NULL,
  alias text NOT NULL,
  normalized text NOT NULL,
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,product_id,locale,normalized)
);
CREATE TABLE catalog.uom (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  product_id uuid NOT NULL,
  code text NOT NULL,
  revision integer NOT NULL DEFAULT 1,
  parent_id uuid,
  base_factor numeric(20,6) NOT NULL,
  barcode text,
  weight_kg numeric(20,6),
  volume_m3 numeric(20,6),
  min_qty numeric(20,6) NOT NULL DEFAULT 1,
  increment_qty numeric(20,6) NOT NULL DEFAULT 1,
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,product_id,code,revision),
  UNIQUE (tenant_id,barcode),
  CHECK (base_factor>0 AND min_qty>0 AND increment_qty>0),
  CHECK (revision>0)
);
CREATE TABLE catalog.product_license (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  product_id uuid NOT NULL,
  party_id uuid NOT NULL,
  licence_ref text NOT NULL,
  expires_at timestamptz NOT NULL,
  status text NOT NULL DEFAULT 'PENDING',
  UNIQUE (tenant_id,id)
);
CREATE TABLE pricing.offer (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  seller_id uuid NOT NULL,
  product_id uuid NOT NULL,
  uom_id uuid NOT NULL,
  status text NOT NULL DEFAULT 'DRAFT',
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,seller_id,product_id,uom_id)
);
CREATE TABLE pricing.price_rule (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  offer_id uuid NOT NULL,
  tier text NOT NULL,
  min_qty numeric(20,6) NOT NULL,
  amount numeric(24,8) NOT NULL,
  currency text NOT NULL,
  effective_from timestamptz NOT NULL,
  effective_to timestamptz,
  status text NOT NULL DEFAULT 'DRAFT',
  UNIQUE (tenant_id,id),
  CHECK (min_qty>0 AND amount>=0),
  CHECK (currency IN ('IQD','USD')),
  CHECK (effective_to IS NULL OR effective_to>effective_from)
);
CREATE TABLE pricing.promotion (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  code text NOT NULL,
  seller_id uuid NOT NULL,
  kind text NOT NULL,
  buy_qty numeric(20,6),
  bonus_qty numeric(20,6),
  rules jsonb NOT NULL,
  effective_from timestamptz NOT NULL,
  effective_to timestamptz,
  status text NOT NULL DEFAULT 'DRAFT',
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,code),
  CHECK (buy_qty IS NULL OR buy_qty>0),
  CHECK (bonus_qty IS NULL OR bonus_qty>0),
  CHECK (effective_to IS NULL OR effective_to>effective_from)
);
CREATE TABLE pricing.tax_rule (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  category_id uuid,
  jurisdiction text NOT NULL,
  rate_bps integer NOT NULL,
  effective_from timestamptz NOT NULL,
  effective_to timestamptz,
  source_ref text NOT NULL,
  status text NOT NULL DEFAULT 'DRAFT',
  UNIQUE (tenant_id,id),
  CHECK (rate_bps BETWEEN 0 AND 10000),
  CHECK (effective_to IS NULL OR effective_to>effective_from)
);
CREATE TABLE inventory.warehouse (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  owner_id uuid NOT NULL,
  branch_id uuid,
  code text NOT NULL,
  name text NOT NULL,
  address_id uuid,
  cold_chain boolean NOT NULL DEFAULT false,
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,code)
);
CREATE TABLE inventory.bin (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  warehouse_id uuid NOT NULL,
  code text NOT NULL,
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,warehouse_id,code)
);
CREATE TABLE inventory.lot (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  product_id uuid NOT NULL,
  owner_id uuid NOT NULL,
  batch_no text NOT NULL,
  expiry_date date,
  manufactured_date date,
  status text NOT NULL DEFAULT 'QUARANTINE',
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,owner_id,product_id,batch_no),
  CHECK (expiry_date IS NULL OR manufactured_date IS NULL OR expiry_date>=manufactured_date)
);
CREATE TABLE inventory.stock_balance (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  warehouse_id uuid NOT NULL,
  bin_id uuid NOT NULL,
  lot_id uuid NOT NULL,
  on_hand numeric(20,6) NOT NULL DEFAULT 0,
  reserved numeric(20,6) NOT NULL DEFAULT 0,
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,warehouse_id,bin_id,lot_id),
  CHECK (on_hand>=0 AND reserved>=0 AND reserved<=on_hand)
);
CREATE TABLE inventory.stock_movement (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  balance_id uuid NOT NULL,
  quantity_delta numeric(20,6) NOT NULL,
  kind text NOT NULL,
  source_key text NOT NULL,
  reason text NOT NULL,
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,source_key),
  CHECK (quantity_delta<>0)
);
CREATE TABLE inventory.reservation (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  balance_id uuid NOT NULL,
  order_line_id uuid NOT NULL,
  quantity numeric(20,6) NOT NULL,
  status text NOT NULL DEFAULT 'ACTIVE',
  expires_at timestamptz,
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,balance_id,order_line_id),
  CHECK (quantity>0)
);
CREATE TABLE inventory.stock_transfer (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  from_warehouse_id uuid NOT NULL,
  to_warehouse_id uuid NOT NULL,
  status text NOT NULL DEFAULT 'DRAFT',
  reference text NOT NULL,
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,reference),
  CHECK (from_warehouse_id<>to_warehouse_id)
);
CREATE TABLE inventory.transfer_line (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  transfer_id uuid NOT NULL,
  lot_id uuid NOT NULL,
  quantity numeric(20,6) NOT NULL,
  UNIQUE (tenant_id,id),
  CHECK (quantity>0)
);
CREATE TABLE inventory.stocktake (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  warehouse_id uuid NOT NULL,
  status text NOT NULL DEFAULT 'DRAFT',
  reference text NOT NULL,
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,reference)
);
CREATE TABLE inventory.stocktake_line (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  stocktake_id uuid NOT NULL,
  balance_id uuid NOT NULL,
  counted_qty numeric(20,6) NOT NULL,
  expected_qty numeric(20,6) NOT NULL,
  UNIQUE (tenant_id,id),
  CHECK (counted_qty>=0 AND expected_qty>=0)
);
CREATE TABLE procurement.purchase_order (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  supplier_id uuid NOT NULL,
  buyer_id uuid NOT NULL,
  reference text NOT NULL,
  status text NOT NULL DEFAULT 'DRAFT',
  currency text NOT NULL,
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,reference)
);
CREATE TABLE procurement.purchase_line (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  purchase_order_id uuid NOT NULL,
  product_id uuid NOT NULL,
  uom_id uuid NOT NULL,
  quantity numeric(20,6) NOT NULL,
  unit_cost numeric(24,8) NOT NULL,
  UNIQUE (tenant_id,id),
  CHECK (quantity>0 AND unit_cost>=0)
);
CREATE TABLE procurement.goods_receipt (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  purchase_order_id uuid NOT NULL,
  warehouse_id uuid NOT NULL,
  reference text NOT NULL,
  status text NOT NULL DEFAULT 'DRAFT',
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,reference)
);
CREATE TABLE procurement.receipt_line (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  receipt_id uuid NOT NULL,
  purchase_line_id uuid NOT NULL,
  lot_id uuid NOT NULL,
  quantity numeric(20,6) NOT NULL,
  quality_status text NOT NULL DEFAULT 'PENDING',
  UNIQUE (tenant_id,id),
  CHECK (quantity>0)
);
CREATE TABLE procurement.supplier_bill (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  purchase_order_id uuid NOT NULL,
  supplier_id uuid NOT NULL,
  reference text NOT NULL,
  currency text NOT NULL,
  total_minor bigint NOT NULL,
  status text NOT NULL DEFAULT 'DRAFT',
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,supplier_id,reference),
  CHECK (total_minor>=0)
);
CREATE TABLE procurement.landed_cost (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  receipt_id uuid NOT NULL,
  kind text NOT NULL,
  amount_minor bigint NOT NULL,
  currency text NOT NULL,
  allocation jsonb NOT NULL,
  UNIQUE (tenant_id,id),
  CHECK (amount_minor>=0)
);
CREATE TABLE treasury.fx_rate (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  kind text NOT NULL,
  base_currency text NOT NULL,
  quote_currency text NOT NULL,
  rate numeric(20,8) NOT NULL,
  source_ref text NOT NULL,
  effective_from timestamptz NOT NULL,
  effective_to timestamptz,
  status text NOT NULL DEFAULT 'DRAFT',
  UNIQUE (tenant_id,id),
  CHECK (rate>0),
  CHECK (kind IN ('OFFICIAL','ACCOUNTING','AUTHORIZED_TRANSACTION','INDICATIVE')),
  CHECK (effective_to IS NULL OR effective_to>effective_from)
);
CREATE TABLE commerce.cart (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  buyer_id uuid NOT NULL,
  status text NOT NULL DEFAULT 'DRAFT',
  client_key text NOT NULL,
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,client_key)
);
CREATE TABLE commerce.cart_line (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  cart_id uuid NOT NULL,
  offer_id uuid NOT NULL,
  quantity numeric(20,6) NOT NULL,
  UNIQUE (tenant_id,id),
  CHECK (quantity>0)
);
CREATE TABLE commerce.quote (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  buyer_id uuid NOT NULL,
  seller_id uuid NOT NULL,
  reference text NOT NULL,
  status text NOT NULL DEFAULT 'DRAFT',
  currency text NOT NULL DEFAULT 'IQD',
  fx_rate_id uuid,
  expires_at timestamptz NOT NULL,
  total_minor bigint NOT NULL,
  policy_snapshot jsonb NOT NULL,
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,reference),
  CHECK (total_minor>=0),
  CHECK (currency='IQD')
);
CREATE TABLE commerce.quote_line (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  quote_id uuid NOT NULL,
  offer_id uuid NOT NULL,
  uom_id uuid NOT NULL,
  paid_qty numeric(20,6) NOT NULL,
  bonus_qty numeric(20,6) NOT NULL DEFAULT 0,
  base_factor numeric(20,6) NOT NULL,
  unit_price numeric(24,8) NOT NULL,
  tax_minor bigint NOT NULL DEFAULT 0,
  total_minor bigint NOT NULL,
  UNIQUE (tenant_id,id),
  CHECK (paid_qty>0 AND bonus_qty>=0 AND base_factor>0 AND unit_price>=0 AND tax_minor>=0 AND total_minor>=0)
);
CREATE TABLE commerce.purchase_group (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  buyer_id uuid NOT NULL,
  reference text NOT NULL,
  status text NOT NULL DEFAULT 'DRAFT',
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,reference)
);
CREATE TABLE commerce.sales_order (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  group_id uuid,
  quote_id uuid NOT NULL,
  buyer_id uuid NOT NULL,
  seller_id uuid NOT NULL,
  reference text NOT NULL,
  status text NOT NULL DEFAULT 'DRAFT',
  total_minor bigint NOT NULL,
  currency text NOT NULL DEFAULT 'IQD',
  client_key text NOT NULL,
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,reference),
  UNIQUE (tenant_id,client_key),
  UNIQUE (tenant_id,quote_id),
  CHECK (total_minor>=0),
  CHECK (currency='IQD')
);
CREATE TABLE commerce.order_line (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  order_id uuid NOT NULL,
  quote_line_id uuid NOT NULL,
  product_id uuid NOT NULL,
  uom_id uuid NOT NULL,
  paid_qty numeric(20,6) NOT NULL,
  bonus_qty numeric(20,6) NOT NULL DEFAULT 0,
  base_factor numeric(20,6) NOT NULL,
  total_minor bigint NOT NULL,
  UNIQUE (tenant_id,id),
  CHECK (paid_qty>0 AND bonus_qty>=0 AND base_factor>0 AND total_minor>=0)
);
CREATE TABLE commerce.order_amendment (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  order_id uuid NOT NULL,
  reason text NOT NULL,
  proposed_changes jsonb NOT NULL,
  status text NOT NULL DEFAULT 'PENDING',
  UNIQUE (tenant_id,id)
);
CREATE TABLE commerce.rfq (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  buyer_id uuid NOT NULL,
  seller_id uuid NOT NULL,
  reference text NOT NULL,
  status text NOT NULL DEFAULT 'OPEN',
  request jsonb NOT NULL,
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,reference)
);
CREATE TABLE commerce.rfq_offer (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  rfq_id uuid NOT NULL,
  quote_id uuid,
  terms jsonb NOT NULL,
  status text NOT NULL DEFAULT 'PROPOSED',
  UNIQUE (tenant_id,id)
);
CREATE TABLE commerce.invoice (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  order_id uuid NOT NULL,
  seller_id uuid NOT NULL,
  buyer_id uuid NOT NULL,
  reference text NOT NULL,
  currency text NOT NULL DEFAULT 'IQD',
  total_minor bigint NOT NULL,
  status text NOT NULL DEFAULT 'DRAFT',
  fx_rate_id uuid,
  issued_at timestamptz,
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,seller_id,reference),
  CHECK (total_minor>=0),
  CHECK (currency='IQD')
);
CREATE TABLE commerce.invoice_line (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  invoice_id uuid NOT NULL,
  order_line_id uuid NOT NULL,
  quantity numeric(20,6) NOT NULL,
  tax_minor bigint NOT NULL,
  total_minor bigint NOT NULL,
  UNIQUE (tenant_id,id),
  CHECK (quantity>0 AND tax_minor>=0 AND total_minor>=0)
);
CREATE TABLE commerce.credit_note (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  invoice_id uuid NOT NULL,
  reference text NOT NULL,
  amount_minor bigint NOT NULL,
  reason text NOT NULL,
  status text NOT NULL DEFAULT 'DRAFT',
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,reference),
  CHECK (amount_minor>0)
);
CREATE TABLE fulfillment.shipment (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  order_id uuid NOT NULL,
  warehouse_id uuid NOT NULL,
  address_id uuid NOT NULL,
  driver_id uuid,
  courier_id uuid,
  status text NOT NULL DEFAULT 'PLANNED',
  reference text NOT NULL,
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,reference)
);
CREATE TABLE fulfillment.shipment_line (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  shipment_id uuid NOT NULL,
  order_line_id uuid NOT NULL,
  lot_id uuid NOT NULL,
  quantity numeric(20,6) NOT NULL,
  accepted_qty numeric(20,6) NOT NULL DEFAULT 0,
  UNIQUE (tenant_id,id),
  CHECK (quantity>0 AND accepted_qty>=0 AND accepted_qty<=quantity)
);
CREATE TABLE fulfillment.pick_task (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  shipment_id uuid NOT NULL,
  reservation_id uuid NOT NULL,
  assignee_id uuid,
  status text NOT NULL DEFAULT 'PENDING',
  UNIQUE (tenant_id,id)
);
CREATE TABLE fulfillment.delivery_proof (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  shipment_id uuid NOT NULL,
  evidence_key text,
  received_by text NOT NULL,
  delivered_at timestamptz NOT NULL,
  point geography(Point,4326),
  accepted boolean NOT NULL,
  UNIQUE (tenant_id,id)
);
CREATE TABLE logistics.vehicle (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  code text NOT NULL,
  registration text NOT NULL,
  cold_chain boolean NOT NULL DEFAULT false,
  status text NOT NULL DEFAULT 'ACTIVE',
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,code)
);
CREATE TABLE logistics.route_plan (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  territory_id uuid,
  driver_id uuid,
  vehicle_id uuid,
  service_date date NOT NULL,
  status text NOT NULL DEFAULT 'DRAFT',
  UNIQUE (tenant_id,id)
);
CREATE TABLE logistics.route_stop (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  route_id uuid NOT NULL,
  address_id uuid NOT NULL,
  shipment_id uuid,
  sequence integer NOT NULL,
  status text NOT NULL DEFAULT 'PLANNED',
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,route_id,sequence),
  CHECK (sequence>0)
);
CREATE TABLE logistics.field_visit (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  assignment_id uuid NOT NULL,
  party_id uuid NOT NULL,
  occurred_at timestamptz NOT NULL,
  point geography(Point,4326),
  accuracy_m numeric(24,8),
  client_key text NOT NULL,
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,client_key)
);
CREATE TABLE logistics.temperature_reading (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  shipment_id uuid NOT NULL,
  sensor_ref text NOT NULL,
  observed_at timestamptz NOT NULL,
  celsius numeric(24,8) NOT NULL,
  UNIQUE (tenant_id,id)
);
CREATE TABLE "returns".return_case (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  order_id uuid NOT NULL,
  reference text NOT NULL,
  reason text NOT NULL,
  status text NOT NULL DEFAULT 'REQUESTED',
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,reference)
);
CREATE TABLE "returns".return_line (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  case_id uuid NOT NULL,
  shipment_line_id uuid NOT NULL,
  quantity numeric(20,6) NOT NULL,
  disposition text NOT NULL DEFAULT 'PENDING',
  UNIQUE (tenant_id,id),
  CHECK (quantity>0)
);
CREATE TABLE payments.provider (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  code text NOT NULL,
  status text NOT NULL DEFAULT 'DISABLED',
  capabilities jsonb NOT NULL,
  UNIQUE (code)
);
CREATE TABLE payments.merchant_account (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  seller_id uuid NOT NULL,
  provider_id uuid NOT NULL,
  merchant_ref text NOT NULL,
  secret_ref text NOT NULL,
  status text NOT NULL DEFAULT 'DISABLED',
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,provider_id,merchant_ref)
);
CREATE TABLE payments.payment_intent (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  order_id uuid NOT NULL,
  merchant_id uuid,
  method text NOT NULL,
  amount_minor bigint NOT NULL,
  currency text NOT NULL DEFAULT 'IQD',
  status text NOT NULL DEFAULT 'PENDING',
  client_key text NOT NULL,
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,client_key),
  CHECK (amount_minor>0),
  CHECK (currency='IQD')
);
CREATE TABLE payments.webhook_inbox (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  merchant_id uuid NOT NULL,
  provider_event_id text NOT NULL,
  verified_intent_id uuid,
  verified_provider_ref text,
  verified_amount_minor bigint,
  verified_currency text,
  payload_digest text NOT NULL,
  payload_key text NOT NULL,
  verified boolean NOT NULL DEFAULT false,
  status text NOT NULL DEFAULT 'RECEIVED',
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,merchant_id,provider_event_id)
);
CREATE TABLE payments.payment_transaction (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  intent_id uuid NOT NULL,
  merchant_id uuid,
  provider_ref text NOT NULL,
  amount_minor bigint NOT NULL,
  currency text NOT NULL DEFAULT 'IQD',
  status text NOT NULL DEFAULT 'CONFIRMED',
  confirmed_at timestamptz NOT NULL,
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,merchant_id,provider_ref),
  UNIQUE (tenant_id,intent_id,provider_ref),
  CHECK (amount_minor>0),
  CHECK (currency='IQD')
);
CREATE TABLE payments.payment_allocation (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  transaction_id uuid NOT NULL,
  invoice_id uuid NOT NULL,
  amount_minor bigint NOT NULL,
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,transaction_id,invoice_id),
  CHECK (amount_minor>0)
);
CREATE TABLE payments.refund (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  transaction_id uuid NOT NULL,
  amount_minor bigint NOT NULL,
  reason text NOT NULL,
  status text NOT NULL DEFAULT 'PENDING',
  reference text NOT NULL,
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,reference),
  CHECK (amount_minor>0)
);
CREATE TABLE payments.payout (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  merchant_id uuid NOT NULL,
  amount_minor bigint NOT NULL,
  beneficiary_ref text NOT NULL,
  status text NOT NULL DEFAULT 'PENDING',
  reference text NOT NULL,
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,reference),
  CHECK (amount_minor>0)
);
CREATE TABLE payments.provider_settlement (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  merchant_id uuid NOT NULL,
  reference text NOT NULL,
  gross_minor bigint NOT NULL,
  fee_minor bigint NOT NULL,
  net_minor bigint NOT NULL,
  status text NOT NULL DEFAULT 'PENDING',
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,merchant_id,reference),
  CHECK (gross_minor>=0 AND fee_minor>=0 AND net_minor=gross_minor-fee_minor)
);
CREATE TABLE credit.facility (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  buyer_id uuid NOT NULL,
  creditor_id uuid NOT NULL,
  limit_minor bigint NOT NULL,
  terms_days integer NOT NULL,
  status text NOT NULL DEFAULT 'PENDING',
  expires_at timestamptz,
  overdue_block boolean NOT NULL DEFAULT true,
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,buyer_id,creditor_id),
  CHECK (limit_minor>=0 AND terms_days>0)
);
CREATE TABLE credit.commitment (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  facility_id uuid NOT NULL,
  order_id uuid NOT NULL,
  amount_minor bigint NOT NULL,
  status text NOT NULL DEFAULT 'ACTIVE',
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,order_id),
  CHECK (amount_minor>0)
);
CREATE TABLE credit.receivable (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  facility_id uuid,
  invoice_id uuid NOT NULL,
  original_minor bigint NOT NULL,
  outstanding_minor bigint NOT NULL,
  due_at timestamptz NOT NULL,
  status text NOT NULL DEFAULT 'OPEN',
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,invoice_id),
  CHECK (original_minor>=0 AND outstanding_minor BETWEEN 0 AND original_minor)
);
CREATE TABLE credit.installment_plan (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  receivable_id uuid NOT NULL,
  due_at timestamptz NOT NULL,
  amount_minor bigint NOT NULL,
  status text NOT NULL DEFAULT 'PENDING',
  UNIQUE (tenant_id,id),
  CHECK (amount_minor>0)
);
CREATE TABLE treasury.cash_session (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  collector_id uuid NOT NULL,
  reference text NOT NULL,
  status text NOT NULL DEFAULT 'OPEN',
  expected_minor bigint NOT NULL DEFAULT 0,
  received_minor bigint NOT NULL DEFAULT 0,
  variance_minor bigint NOT NULL DEFAULT 0,
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,reference),
  CHECK (expected_minor>=0 AND received_minor>=0),
  CHECK (variance_minor=received_minor-expected_minor)
);
CREATE TABLE treasury.cod_receipt (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  cash_session_id uuid NOT NULL,
  shipment_id uuid NOT NULL,
  invoice_id uuid NOT NULL,
  amount_minor bigint NOT NULL,
  reference text NOT NULL,
  collected_at timestamptz NOT NULL,
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,reference),
  CHECK (amount_minor>0)
);
CREATE TABLE treasury.cash_handover (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  cash_session_id uuid NOT NULL,
  received_by uuid NOT NULL,
  amount_minor bigint NOT NULL,
  evidence_key text NOT NULL,
  received_at timestamptz NOT NULL,
  UNIQUE (tenant_id,id),
  CHECK (amount_minor>0)
);
CREATE TABLE accounting.ledger (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  legal_entity_id uuid NOT NULL,
  code text NOT NULL,
  currency text NOT NULL DEFAULT 'IQD',
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,code)
);
CREATE TABLE accounting.account (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  ledger_id uuid NOT NULL,
  code text NOT NULL,
  name text NOT NULL,
  kind text NOT NULL,
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,ledger_id,code)
);
CREATE TABLE accounting.period (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  ledger_id uuid NOT NULL,
  starts_on date NOT NULL,
  ends_on date NOT NULL,
  status text NOT NULL DEFAULT 'OPEN',
  UNIQUE (tenant_id,id),
  CHECK (ends_on>=starts_on),
  CHECK (status IN ('OPEN','CLOSED'))
);
CREATE TABLE accounting.journal (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  ledger_id uuid NOT NULL,
  period_id uuid NOT NULL,
  reference text NOT NULL,
  source_key text NOT NULL,
  status text NOT NULL DEFAULT 'DRAFT',
  entry_date date NOT NULL,
  maker_id uuid NOT NULL,
  checker_id uuid,
  reversed_journal_id uuid,
  posted_at timestamptz,
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,ledger_id,reference),
  UNIQUE (tenant_id,ledger_id,source_key),
  UNIQUE (tenant_id,reversed_journal_id),
  CHECK (status IN ('DRAFT','POSTED')),
  CHECK (checker_id IS NULL OR checker_id<>maker_id)
);
CREATE TABLE accounting.journal_line (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  journal_id uuid NOT NULL,
  account_id uuid NOT NULL,
  debit_minor bigint NOT NULL DEFAULT 0,
  credit_minor bigint NOT NULL DEFAULT 0,
  memo text,
  UNIQUE (tenant_id,id),
  CHECK ((debit_minor>0 AND credit_minor=0) OR (credit_minor>0 AND debit_minor=0))
);
CREATE TABLE notifications.consent (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  membership_id uuid NOT NULL,
  channel text NOT NULL,
  purpose text NOT NULL,
  granted boolean NOT NULL,
  recorded_at timestamptz NOT NULL,
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,membership_id,channel,purpose)
);
CREATE TABLE notifications.template (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  code text NOT NULL,
  locale text NOT NULL,
  channel text NOT NULL,
  body text NOT NULL,
  status text NOT NULL DEFAULT 'DRAFT',
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,code,locale,channel)
);
CREATE TABLE notifications.message (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  membership_id uuid NOT NULL,
  template_id uuid,
  channel text NOT NULL,
  status text NOT NULL DEFAULT 'QUEUED',
  dedupe_key text NOT NULL,
  payload jsonb NOT NULL,
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,dedupe_key)
);
CREATE TABLE notifications.delivery_attempt (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  message_id uuid NOT NULL,
  provider_ref text,
  status text NOT NULL,
  attempted_at timestamptz NOT NULL,
  UNIQUE (tenant_id,id)
);
CREATE TABLE integrations.idempotency (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  membership_id uuid NOT NULL,
  operation_key text NOT NULL,
  request_hash text NOT NULL,
  response_ref uuid,
  status text NOT NULL DEFAULT 'PENDING',
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,membership_id,operation_key)
);
CREATE TABLE integrations.outbox (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  event_type text NOT NULL,
  aggregate_id uuid NOT NULL,
  payload jsonb NOT NULL,
  dedupe_key text NOT NULL,
  published_at timestamptz,
  attempts integer NOT NULL DEFAULT 0,
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,dedupe_key)
);
CREATE TABLE integrations.consumer_receipt (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  consumer text NOT NULL,
  event_id uuid NOT NULL,
  processed_at timestamptz NOT NULL,
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,consumer,event_id)
);
CREATE TABLE integrations.sync_operation (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  membership_id uuid NOT NULL,
  device_id uuid,
  client_key text NOT NULL,
  payload_hash text NOT NULL,
  status text NOT NULL DEFAULT 'PENDING',
  result_ref uuid,
  UNIQUE (tenant_id,id),
  UNIQUE (tenant_id,membership_id,client_key)
);
CREATE TABLE integrations.bulk_job (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  kind text NOT NULL,
  object_key text NOT NULL,
  status text NOT NULL DEFAULT 'DRAFT',
  result_key text,
  requested_by uuid NOT NULL,
  UNIQUE (tenant_id,id)
);
CREATE TABLE analytics.metric_snapshot (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  metric text NOT NULL,
  dimension jsonb NOT NULL,
  period_start timestamptz NOT NULL,
  period_end timestamptz NOT NULL,
  value numeric(24,8) NOT NULL,
  currency text,
  refreshed_at timestamptz NOT NULL,
  UNIQUE (tenant_id,id),
  CHECK (period_end>period_start)
);
CREATE TABLE audit.event (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id uuid NOT NULL,
  scope_id uuid,
  version integer NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  archived_at timestamptz,
  actor_id uuid,
  resource text NOT NULL,
  resource_id uuid NOT NULL,
  action text NOT NULL,
  before_data jsonb,
  after_data jsonb,
  correlation_id text,
  event_hash text NOT NULL,
  UNIQUE (tenant_id,id)
);
ALTER TABLE organizations.scope ADD CONSTRAINT fk_scope_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE organizations.scope ADD CONSTRAINT fk_scope_parent_id FOREIGN KEY (tenant_id,parent_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE organizations.membership ADD CONSTRAINT fk_membership_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE organizations.membership ADD CONSTRAINT fk_membership_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE organizations.membership ADD CONSTRAINT fk_membership_principal_id FOREIGN KEY (principal_id) REFERENCES identity.principal (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE "authorization".role ADD CONSTRAINT fk_role_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE "authorization".role ADD CONSTRAINT fk_role_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE "authorization".role_permission ADD CONSTRAINT fk_role_permission_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE "authorization".role_permission ADD CONSTRAINT fk_role_permission_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE "authorization".role_permission ADD CONSTRAINT fk_role_permission_role_id FOREIGN KEY (tenant_id,role_id) REFERENCES "authorization".role (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE "authorization".assignment ADD CONSTRAINT fk_assignment_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE "authorization".assignment ADD CONSTRAINT fk_assignment_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE "authorization".assignment ADD CONSTRAINT fk_assignment_membership_id FOREIGN KEY (tenant_id,membership_id) REFERENCES organizations.membership (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE "authorization".assignment ADD CONSTRAINT fk_assignment_role_id FOREIGN KEY (tenant_id,role_id) REFERENCES "authorization".role (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE "authorization".assignment ADD CONSTRAINT fk_assignment_assigned_scope_id FOREIGN KEY (tenant_id,assigned_scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE identity.device ADD CONSTRAINT fk_device_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE identity.device ADD CONSTRAINT fk_device_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE identity.device ADD CONSTRAINT fk_device_membership_id FOREIGN KEY (tenant_id,membership_id) REFERENCES organizations.membership (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE identity.session ADD CONSTRAINT fk_session_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE identity.session ADD CONSTRAINT fk_session_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE identity.session ADD CONSTRAINT fk_session_membership_id FOREIGN KEY (tenant_id,membership_id) REFERENCES organizations.membership (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE identity.session ADD CONSTRAINT fk_session_device_id FOREIGN KEY (tenant_id,device_id) REFERENCES identity.device (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE logistics.district ADD CONSTRAINT fk_district_governorate_id FOREIGN KEY (governorate_id) REFERENCES logistics.governorate (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE logistics.zone ADD CONSTRAINT fk_zone_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE logistics.zone ADD CONSTRAINT fk_zone_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE logistics.zone ADD CONSTRAINT fk_zone_governorate_id FOREIGN KEY (governorate_id) REFERENCES logistics.governorate (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE logistics.address ADD CONSTRAINT fk_address_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE logistics.address ADD CONSTRAINT fk_address_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE logistics.address ADD CONSTRAINT fk_address_governorate_id FOREIGN KEY (governorate_id) REFERENCES logistics.governorate (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE logistics.address ADD CONSTRAINT fk_address_district_id FOREIGN KEY (district_id) REFERENCES logistics.district (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE logistics.shipping_tariff ADD CONSTRAINT fk_shipping_tariff_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE logistics.shipping_tariff ADD CONSTRAINT fk_shipping_tariff_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE logistics.shipping_tariff ADD CONSTRAINT fk_shipping_tariff_zone_id FOREIGN KEY (tenant_id,zone_id) REFERENCES logistics.zone (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE logistics.shipping_tariff ADD CONSTRAINT fk_shipping_tariff_origin_zone_id FOREIGN KEY (tenant_id,origin_zone_id) REFERENCES logistics.zone (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE organizations.party ADD CONSTRAINT fk_party_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE organizations.party ADD CONSTRAINT fk_party_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE organizations.branch ADD CONSTRAINT fk_branch_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE organizations.branch ADD CONSTRAINT fk_branch_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE organizations.branch ADD CONSTRAINT fk_branch_party_id FOREIGN KEY (tenant_id,party_id) REFERENCES organizations.party (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE organizations.branch ADD CONSTRAINT fk_branch_address_id FOREIGN KEY (tenant_id,address_id) REFERENCES logistics.address (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE organizations.party_member ADD CONSTRAINT fk_party_member_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE organizations.party_member ADD CONSTRAINT fk_party_member_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE organizations.party_member ADD CONSTRAINT fk_party_member_party_id FOREIGN KEY (tenant_id,party_id) REFERENCES organizations.party (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE organizations.party_member ADD CONSTRAINT fk_party_member_membership_id FOREIGN KEY (tenant_id,membership_id) REFERENCES organizations.membership (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE organizations.territory ADD CONSTRAINT fk_territory_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE organizations.territory ADD CONSTRAINT fk_territory_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE organizations.territory ADD CONSTRAINT fk_territory_zone_id FOREIGN KEY (tenant_id,zone_id) REFERENCES logistics.zone (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE organizations.field_assignment ADD CONSTRAINT fk_field_assignment_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE organizations.field_assignment ADD CONSTRAINT fk_field_assignment_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE organizations.field_assignment ADD CONSTRAINT fk_field_assignment_membership_id FOREIGN KEY (tenant_id,membership_id) REFERENCES organizations.membership (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE organizations.field_assignment ADD CONSTRAINT fk_field_assignment_territory_id FOREIGN KEY (tenant_id,territory_id) REFERENCES organizations.territory (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE organizations.retailer_profile ADD CONSTRAINT fk_retailer_profile_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE organizations.retailer_profile ADD CONSTRAINT fk_retailer_profile_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE organizations.retailer_profile ADD CONSTRAINT fk_retailer_profile_party_id FOREIGN KEY (tenant_id,party_id) REFERENCES organizations.party (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE organizations.retailer_profile ADD CONSTRAINT fk_retailer_profile_address_id FOREIGN KEY (tenant_id,address_id) REFERENCES logistics.address (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE organizations.supplier_profile ADD CONSTRAINT fk_supplier_profile_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE organizations.supplier_profile ADD CONSTRAINT fk_supplier_profile_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE organizations.supplier_profile ADD CONSTRAINT fk_supplier_profile_party_id FOREIGN KEY (tenant_id,party_id) REFERENCES organizations.party (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE compliance.kyc_case ADD CONSTRAINT fk_kyc_case_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE compliance.kyc_case ADD CONSTRAINT fk_kyc_case_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE compliance.kyc_case ADD CONSTRAINT fk_kyc_case_party_id FOREIGN KEY (tenant_id,party_id) REFERENCES organizations.party (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE compliance.kyc_case ADD CONSTRAINT fk_kyc_case_decided_by FOREIGN KEY (tenant_id,decided_by) REFERENCES organizations.membership (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE compliance.document ADD CONSTRAINT fk_document_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE compliance.document ADD CONSTRAINT fk_document_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE compliance.document ADD CONSTRAINT fk_document_party_id FOREIGN KEY (tenant_id,party_id) REFERENCES organizations.party (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE compliance.document ADD CONSTRAINT fk_document_kyc_case_id FOREIGN KEY (tenant_id,kyc_case_id) REFERENCES compliance.kyc_case (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE compliance.kyc_decision ADD CONSTRAINT fk_kyc_decision_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE compliance.kyc_decision ADD CONSTRAINT fk_kyc_decision_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE compliance.kyc_decision ADD CONSTRAINT fk_kyc_decision_case_id FOREIGN KEY (tenant_id,case_id) REFERENCES compliance.kyc_case (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE compliance.kyc_decision ADD CONSTRAINT fk_kyc_decision_reviewer_id FOREIGN KEY (tenant_id,reviewer_id) REFERENCES organizations.membership (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE compliance.risk_case ADD CONSTRAINT fk_risk_case_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE compliance.risk_case ADD CONSTRAINT fk_risk_case_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE compliance.risk_case ADD CONSTRAINT fk_risk_case_party_id FOREIGN KEY (tenant_id,party_id) REFERENCES organizations.party (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE compliance.policy ADD CONSTRAINT fk_policy_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE compliance.policy ADD CONSTRAINT fk_policy_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE compliance.approval ADD CONSTRAINT fk_approval_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE compliance.approval ADD CONSTRAINT fk_approval_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE compliance.approval ADD CONSTRAINT fk_approval_maker_id FOREIGN KEY (tenant_id,maker_id) REFERENCES organizations.membership (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE compliance.approval ADD CONSTRAINT fk_approval_checker_id FOREIGN KEY (tenant_id,checker_id) REFERENCES organizations.membership (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE catalog.brand ADD CONSTRAINT fk_brand_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE catalog.brand ADD CONSTRAINT fk_brand_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE catalog.category ADD CONSTRAINT fk_category_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE catalog.category ADD CONSTRAINT fk_category_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE catalog.category ADD CONSTRAINT fk_category_parent_id FOREIGN KEY (tenant_id,parent_id) REFERENCES catalog.category (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE catalog.product ADD CONSTRAINT fk_product_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE catalog.product ADD CONSTRAINT fk_product_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE catalog.product ADD CONSTRAINT fk_product_brand_id FOREIGN KEY (tenant_id,brand_id) REFERENCES catalog.brand (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE catalog.product ADD CONSTRAINT fk_product_category_id FOREIGN KEY (tenant_id,category_id) REFERENCES catalog.category (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE catalog.product_alias ADD CONSTRAINT fk_product_alias_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE catalog.product_alias ADD CONSTRAINT fk_product_alias_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE catalog.product_alias ADD CONSTRAINT fk_product_alias_product_id FOREIGN KEY (tenant_id,product_id) REFERENCES catalog.product (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE catalog.uom ADD CONSTRAINT fk_uom_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE catalog.uom ADD CONSTRAINT fk_uom_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE catalog.uom ADD CONSTRAINT fk_uom_product_id FOREIGN KEY (tenant_id,product_id) REFERENCES catalog.product (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE catalog.uom ADD CONSTRAINT fk_uom_parent_id FOREIGN KEY (tenant_id,parent_id) REFERENCES catalog.uom (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE catalog.product_license ADD CONSTRAINT fk_product_license_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE catalog.product_license ADD CONSTRAINT fk_product_license_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE catalog.product_license ADD CONSTRAINT fk_product_license_product_id FOREIGN KEY (tenant_id,product_id) REFERENCES catalog.product (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE catalog.product_license ADD CONSTRAINT fk_product_license_party_id FOREIGN KEY (tenant_id,party_id) REFERENCES organizations.party (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE pricing.offer ADD CONSTRAINT fk_offer_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE pricing.offer ADD CONSTRAINT fk_offer_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE pricing.offer ADD CONSTRAINT fk_offer_seller_id FOREIGN KEY (tenant_id,seller_id) REFERENCES organizations.party (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE pricing.offer ADD CONSTRAINT fk_offer_product_id FOREIGN KEY (tenant_id,product_id) REFERENCES catalog.product (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE pricing.offer ADD CONSTRAINT fk_offer_uom_id FOREIGN KEY (tenant_id,uom_id) REFERENCES catalog.uom (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE pricing.price_rule ADD CONSTRAINT fk_price_rule_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE pricing.price_rule ADD CONSTRAINT fk_price_rule_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE pricing.price_rule ADD CONSTRAINT fk_price_rule_offer_id FOREIGN KEY (tenant_id,offer_id) REFERENCES pricing.offer (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE pricing.promotion ADD CONSTRAINT fk_promotion_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE pricing.promotion ADD CONSTRAINT fk_promotion_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE pricing.promotion ADD CONSTRAINT fk_promotion_seller_id FOREIGN KEY (tenant_id,seller_id) REFERENCES organizations.party (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE pricing.tax_rule ADD CONSTRAINT fk_tax_rule_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE pricing.tax_rule ADD CONSTRAINT fk_tax_rule_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE pricing.tax_rule ADD CONSTRAINT fk_tax_rule_category_id FOREIGN KEY (tenant_id,category_id) REFERENCES catalog.category (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE inventory.warehouse ADD CONSTRAINT fk_warehouse_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE inventory.warehouse ADD CONSTRAINT fk_warehouse_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE inventory.warehouse ADD CONSTRAINT fk_warehouse_owner_id FOREIGN KEY (tenant_id,owner_id) REFERENCES organizations.party (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE inventory.warehouse ADD CONSTRAINT fk_warehouse_branch_id FOREIGN KEY (tenant_id,branch_id) REFERENCES organizations.branch (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE inventory.warehouse ADD CONSTRAINT fk_warehouse_address_id FOREIGN KEY (tenant_id,address_id) REFERENCES logistics.address (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE inventory.bin ADD CONSTRAINT fk_bin_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE inventory.bin ADD CONSTRAINT fk_bin_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE inventory.bin ADD CONSTRAINT fk_bin_warehouse_id FOREIGN KEY (tenant_id,warehouse_id) REFERENCES inventory.warehouse (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE inventory.lot ADD CONSTRAINT fk_lot_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE inventory.lot ADD CONSTRAINT fk_lot_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE inventory.lot ADD CONSTRAINT fk_lot_product_id FOREIGN KEY (tenant_id,product_id) REFERENCES catalog.product (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE inventory.lot ADD CONSTRAINT fk_lot_owner_id FOREIGN KEY (tenant_id,owner_id) REFERENCES organizations.party (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE inventory.stock_balance ADD CONSTRAINT fk_stock_balance_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE inventory.stock_balance ADD CONSTRAINT fk_stock_balance_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE inventory.stock_balance ADD CONSTRAINT fk_stock_balance_warehouse_id FOREIGN KEY (tenant_id,warehouse_id) REFERENCES inventory.warehouse (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE inventory.stock_balance ADD CONSTRAINT fk_stock_balance_bin_id FOREIGN KEY (tenant_id,bin_id) REFERENCES inventory.bin (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE inventory.stock_balance ADD CONSTRAINT fk_stock_balance_lot_id FOREIGN KEY (tenant_id,lot_id) REFERENCES inventory.lot (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE inventory.stock_movement ADD CONSTRAINT fk_stock_movement_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE inventory.stock_movement ADD CONSTRAINT fk_stock_movement_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE inventory.stock_movement ADD CONSTRAINT fk_stock_movement_balance_id FOREIGN KEY (tenant_id,balance_id) REFERENCES inventory.stock_balance (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE inventory.reservation ADD CONSTRAINT fk_reservation_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE inventory.reservation ADD CONSTRAINT fk_reservation_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE inventory.reservation ADD CONSTRAINT fk_reservation_balance_id FOREIGN KEY (tenant_id,balance_id) REFERENCES inventory.stock_balance (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE inventory.reservation ADD CONSTRAINT fk_reservation_order_line_id FOREIGN KEY (tenant_id,order_line_id) REFERENCES commerce.order_line (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE inventory.stock_transfer ADD CONSTRAINT fk_stock_transfer_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE inventory.stock_transfer ADD CONSTRAINT fk_stock_transfer_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE inventory.stock_transfer ADD CONSTRAINT fk_stock_transfer_from_warehouse_id FOREIGN KEY (tenant_id,from_warehouse_id) REFERENCES inventory.warehouse (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE inventory.stock_transfer ADD CONSTRAINT fk_stock_transfer_to_warehouse_id FOREIGN KEY (tenant_id,to_warehouse_id) REFERENCES inventory.warehouse (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE inventory.transfer_line ADD CONSTRAINT fk_transfer_line_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE inventory.transfer_line ADD CONSTRAINT fk_transfer_line_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE inventory.transfer_line ADD CONSTRAINT fk_transfer_line_transfer_id FOREIGN KEY (tenant_id,transfer_id) REFERENCES inventory.stock_transfer (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE inventory.transfer_line ADD CONSTRAINT fk_transfer_line_lot_id FOREIGN KEY (tenant_id,lot_id) REFERENCES inventory.lot (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE inventory.stocktake ADD CONSTRAINT fk_stocktake_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE inventory.stocktake ADD CONSTRAINT fk_stocktake_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE inventory.stocktake ADD CONSTRAINT fk_stocktake_warehouse_id FOREIGN KEY (tenant_id,warehouse_id) REFERENCES inventory.warehouse (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE inventory.stocktake_line ADD CONSTRAINT fk_stocktake_line_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE inventory.stocktake_line ADD CONSTRAINT fk_stocktake_line_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE inventory.stocktake_line ADD CONSTRAINT fk_stocktake_line_stocktake_id FOREIGN KEY (tenant_id,stocktake_id) REFERENCES inventory.stocktake (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE inventory.stocktake_line ADD CONSTRAINT fk_stocktake_line_balance_id FOREIGN KEY (tenant_id,balance_id) REFERENCES inventory.stock_balance (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE procurement.purchase_order ADD CONSTRAINT fk_purchase_order_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE procurement.purchase_order ADD CONSTRAINT fk_purchase_order_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE procurement.purchase_order ADD CONSTRAINT fk_purchase_order_supplier_id FOREIGN KEY (tenant_id,supplier_id) REFERENCES organizations.party (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE procurement.purchase_order ADD CONSTRAINT fk_purchase_order_buyer_id FOREIGN KEY (tenant_id,buyer_id) REFERENCES organizations.party (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE procurement.purchase_line ADD CONSTRAINT fk_purchase_line_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE procurement.purchase_line ADD CONSTRAINT fk_purchase_line_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE procurement.purchase_line ADD CONSTRAINT fk_purchase_line_purchase_order_id FOREIGN KEY (tenant_id,purchase_order_id) REFERENCES procurement.purchase_order (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE procurement.purchase_line ADD CONSTRAINT fk_purchase_line_product_id FOREIGN KEY (tenant_id,product_id) REFERENCES catalog.product (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE procurement.purchase_line ADD CONSTRAINT fk_purchase_line_uom_id FOREIGN KEY (tenant_id,uom_id) REFERENCES catalog.uom (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE procurement.goods_receipt ADD CONSTRAINT fk_goods_receipt_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE procurement.goods_receipt ADD CONSTRAINT fk_goods_receipt_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE procurement.goods_receipt ADD CONSTRAINT fk_goods_receipt_purchase_order_id FOREIGN KEY (tenant_id,purchase_order_id) REFERENCES procurement.purchase_order (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE procurement.goods_receipt ADD CONSTRAINT fk_goods_receipt_warehouse_id FOREIGN KEY (tenant_id,warehouse_id) REFERENCES inventory.warehouse (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE procurement.receipt_line ADD CONSTRAINT fk_receipt_line_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE procurement.receipt_line ADD CONSTRAINT fk_receipt_line_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE procurement.receipt_line ADD CONSTRAINT fk_receipt_line_receipt_id FOREIGN KEY (tenant_id,receipt_id) REFERENCES procurement.goods_receipt (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE procurement.receipt_line ADD CONSTRAINT fk_receipt_line_purchase_line_id FOREIGN KEY (tenant_id,purchase_line_id) REFERENCES procurement.purchase_line (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE procurement.receipt_line ADD CONSTRAINT fk_receipt_line_lot_id FOREIGN KEY (tenant_id,lot_id) REFERENCES inventory.lot (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE procurement.supplier_bill ADD CONSTRAINT fk_supplier_bill_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE procurement.supplier_bill ADD CONSTRAINT fk_supplier_bill_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE procurement.supplier_bill ADD CONSTRAINT fk_supplier_bill_purchase_order_id FOREIGN KEY (tenant_id,purchase_order_id) REFERENCES procurement.purchase_order (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE procurement.supplier_bill ADD CONSTRAINT fk_supplier_bill_supplier_id FOREIGN KEY (tenant_id,supplier_id) REFERENCES organizations.party (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE procurement.landed_cost ADD CONSTRAINT fk_landed_cost_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE procurement.landed_cost ADD CONSTRAINT fk_landed_cost_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE procurement.landed_cost ADD CONSTRAINT fk_landed_cost_receipt_id FOREIGN KEY (tenant_id,receipt_id) REFERENCES procurement.goods_receipt (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE treasury.fx_rate ADD CONSTRAINT fk_fx_rate_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE treasury.fx_rate ADD CONSTRAINT fk_fx_rate_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.cart ADD CONSTRAINT fk_cart_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.cart ADD CONSTRAINT fk_cart_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.cart ADD CONSTRAINT fk_cart_buyer_id FOREIGN KEY (tenant_id,buyer_id) REFERENCES organizations.party (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.cart_line ADD CONSTRAINT fk_cart_line_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.cart_line ADD CONSTRAINT fk_cart_line_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.cart_line ADD CONSTRAINT fk_cart_line_cart_id FOREIGN KEY (tenant_id,cart_id) REFERENCES commerce.cart (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.cart_line ADD CONSTRAINT fk_cart_line_offer_id FOREIGN KEY (tenant_id,offer_id) REFERENCES pricing.offer (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.quote ADD CONSTRAINT fk_quote_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.quote ADD CONSTRAINT fk_quote_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.quote ADD CONSTRAINT fk_quote_buyer_id FOREIGN KEY (tenant_id,buyer_id) REFERENCES organizations.party (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.quote ADD CONSTRAINT fk_quote_seller_id FOREIGN KEY (tenant_id,seller_id) REFERENCES organizations.party (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.quote ADD CONSTRAINT fk_quote_fx_rate_id FOREIGN KEY (tenant_id,fx_rate_id) REFERENCES treasury.fx_rate (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.quote_line ADD CONSTRAINT fk_quote_line_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.quote_line ADD CONSTRAINT fk_quote_line_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.quote_line ADD CONSTRAINT fk_quote_line_quote_id FOREIGN KEY (tenant_id,quote_id) REFERENCES commerce.quote (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.quote_line ADD CONSTRAINT fk_quote_line_offer_id FOREIGN KEY (tenant_id,offer_id) REFERENCES pricing.offer (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.quote_line ADD CONSTRAINT fk_quote_line_uom_id FOREIGN KEY (tenant_id,uom_id) REFERENCES catalog.uom (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.purchase_group ADD CONSTRAINT fk_purchase_group_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.purchase_group ADD CONSTRAINT fk_purchase_group_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.purchase_group ADD CONSTRAINT fk_purchase_group_buyer_id FOREIGN KEY (tenant_id,buyer_id) REFERENCES organizations.party (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.sales_order ADD CONSTRAINT fk_sales_order_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.sales_order ADD CONSTRAINT fk_sales_order_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.sales_order ADD CONSTRAINT fk_sales_order_group_id FOREIGN KEY (tenant_id,group_id) REFERENCES commerce.purchase_group (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.sales_order ADD CONSTRAINT fk_sales_order_quote_id FOREIGN KEY (tenant_id,quote_id) REFERENCES commerce.quote (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.sales_order ADD CONSTRAINT fk_sales_order_buyer_id FOREIGN KEY (tenant_id,buyer_id) REFERENCES organizations.party (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.sales_order ADD CONSTRAINT fk_sales_order_seller_id FOREIGN KEY (tenant_id,seller_id) REFERENCES organizations.party (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.order_line ADD CONSTRAINT fk_order_line_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.order_line ADD CONSTRAINT fk_order_line_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.order_line ADD CONSTRAINT fk_order_line_order_id FOREIGN KEY (tenant_id,order_id) REFERENCES commerce.sales_order (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.order_line ADD CONSTRAINT fk_order_line_quote_line_id FOREIGN KEY (tenant_id,quote_line_id) REFERENCES commerce.quote_line (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.order_line ADD CONSTRAINT fk_order_line_product_id FOREIGN KEY (tenant_id,product_id) REFERENCES catalog.product (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.order_line ADD CONSTRAINT fk_order_line_uom_id FOREIGN KEY (tenant_id,uom_id) REFERENCES catalog.uom (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.order_amendment ADD CONSTRAINT fk_order_amendment_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.order_amendment ADD CONSTRAINT fk_order_amendment_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.order_amendment ADD CONSTRAINT fk_order_amendment_order_id FOREIGN KEY (tenant_id,order_id) REFERENCES commerce.sales_order (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.rfq ADD CONSTRAINT fk_rfq_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.rfq ADD CONSTRAINT fk_rfq_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.rfq ADD CONSTRAINT fk_rfq_buyer_id FOREIGN KEY (tenant_id,buyer_id) REFERENCES organizations.party (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.rfq ADD CONSTRAINT fk_rfq_seller_id FOREIGN KEY (tenant_id,seller_id) REFERENCES organizations.party (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.rfq_offer ADD CONSTRAINT fk_rfq_offer_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.rfq_offer ADD CONSTRAINT fk_rfq_offer_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.rfq_offer ADD CONSTRAINT fk_rfq_offer_rfq_id FOREIGN KEY (tenant_id,rfq_id) REFERENCES commerce.rfq (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.rfq_offer ADD CONSTRAINT fk_rfq_offer_quote_id FOREIGN KEY (tenant_id,quote_id) REFERENCES commerce.quote (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.invoice ADD CONSTRAINT fk_invoice_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.invoice ADD CONSTRAINT fk_invoice_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.invoice ADD CONSTRAINT fk_invoice_order_id FOREIGN KEY (tenant_id,order_id) REFERENCES commerce.sales_order (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.invoice ADD CONSTRAINT fk_invoice_seller_id FOREIGN KEY (tenant_id,seller_id) REFERENCES organizations.party (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.invoice ADD CONSTRAINT fk_invoice_buyer_id FOREIGN KEY (tenant_id,buyer_id) REFERENCES organizations.party (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.invoice ADD CONSTRAINT fk_invoice_fx_rate_id FOREIGN KEY (tenant_id,fx_rate_id) REFERENCES treasury.fx_rate (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.invoice_line ADD CONSTRAINT fk_invoice_line_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.invoice_line ADD CONSTRAINT fk_invoice_line_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.invoice_line ADD CONSTRAINT fk_invoice_line_invoice_id FOREIGN KEY (tenant_id,invoice_id) REFERENCES commerce.invoice (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.invoice_line ADD CONSTRAINT fk_invoice_line_order_line_id FOREIGN KEY (tenant_id,order_line_id) REFERENCES commerce.order_line (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.credit_note ADD CONSTRAINT fk_credit_note_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.credit_note ADD CONSTRAINT fk_credit_note_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE commerce.credit_note ADD CONSTRAINT fk_credit_note_invoice_id FOREIGN KEY (tenant_id,invoice_id) REFERENCES commerce.invoice (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE fulfillment.shipment ADD CONSTRAINT fk_shipment_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE fulfillment.shipment ADD CONSTRAINT fk_shipment_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE fulfillment.shipment ADD CONSTRAINT fk_shipment_order_id FOREIGN KEY (tenant_id,order_id) REFERENCES commerce.sales_order (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE fulfillment.shipment ADD CONSTRAINT fk_shipment_warehouse_id FOREIGN KEY (tenant_id,warehouse_id) REFERENCES inventory.warehouse (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE fulfillment.shipment ADD CONSTRAINT fk_shipment_address_id FOREIGN KEY (tenant_id,address_id) REFERENCES logistics.address (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE fulfillment.shipment ADD CONSTRAINT fk_shipment_driver_id FOREIGN KEY (tenant_id,driver_id) REFERENCES organizations.membership (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE fulfillment.shipment ADD CONSTRAINT fk_shipment_courier_id FOREIGN KEY (tenant_id,courier_id) REFERENCES organizations.party (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE fulfillment.shipment_line ADD CONSTRAINT fk_shipment_line_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE fulfillment.shipment_line ADD CONSTRAINT fk_shipment_line_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE fulfillment.shipment_line ADD CONSTRAINT fk_shipment_line_shipment_id FOREIGN KEY (tenant_id,shipment_id) REFERENCES fulfillment.shipment (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE fulfillment.shipment_line ADD CONSTRAINT fk_shipment_line_order_line_id FOREIGN KEY (tenant_id,order_line_id) REFERENCES commerce.order_line (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE fulfillment.shipment_line ADD CONSTRAINT fk_shipment_line_lot_id FOREIGN KEY (tenant_id,lot_id) REFERENCES inventory.lot (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE fulfillment.pick_task ADD CONSTRAINT fk_pick_task_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE fulfillment.pick_task ADD CONSTRAINT fk_pick_task_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE fulfillment.pick_task ADD CONSTRAINT fk_pick_task_shipment_id FOREIGN KEY (tenant_id,shipment_id) REFERENCES fulfillment.shipment (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE fulfillment.pick_task ADD CONSTRAINT fk_pick_task_reservation_id FOREIGN KEY (tenant_id,reservation_id) REFERENCES inventory.reservation (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE fulfillment.pick_task ADD CONSTRAINT fk_pick_task_assignee_id FOREIGN KEY (tenant_id,assignee_id) REFERENCES organizations.membership (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE fulfillment.delivery_proof ADD CONSTRAINT fk_delivery_proof_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE fulfillment.delivery_proof ADD CONSTRAINT fk_delivery_proof_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE fulfillment.delivery_proof ADD CONSTRAINT fk_delivery_proof_shipment_id FOREIGN KEY (tenant_id,shipment_id) REFERENCES fulfillment.shipment (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE logistics.vehicle ADD CONSTRAINT fk_vehicle_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE logistics.vehicle ADD CONSTRAINT fk_vehicle_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE logistics.route_plan ADD CONSTRAINT fk_route_plan_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE logistics.route_plan ADD CONSTRAINT fk_route_plan_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE logistics.route_plan ADD CONSTRAINT fk_route_plan_territory_id FOREIGN KEY (tenant_id,territory_id) REFERENCES organizations.territory (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE logistics.route_plan ADD CONSTRAINT fk_route_plan_driver_id FOREIGN KEY (tenant_id,driver_id) REFERENCES organizations.membership (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE logistics.route_plan ADD CONSTRAINT fk_route_plan_vehicle_id FOREIGN KEY (tenant_id,vehicle_id) REFERENCES logistics.vehicle (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE logistics.route_stop ADD CONSTRAINT fk_route_stop_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE logistics.route_stop ADD CONSTRAINT fk_route_stop_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE logistics.route_stop ADD CONSTRAINT fk_route_stop_route_id FOREIGN KEY (tenant_id,route_id) REFERENCES logistics.route_plan (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE logistics.route_stop ADD CONSTRAINT fk_route_stop_address_id FOREIGN KEY (tenant_id,address_id) REFERENCES logistics.address (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE logistics.route_stop ADD CONSTRAINT fk_route_stop_shipment_id FOREIGN KEY (tenant_id,shipment_id) REFERENCES fulfillment.shipment (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE logistics.field_visit ADD CONSTRAINT fk_field_visit_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE logistics.field_visit ADD CONSTRAINT fk_field_visit_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE logistics.field_visit ADD CONSTRAINT fk_field_visit_assignment_id FOREIGN KEY (tenant_id,assignment_id) REFERENCES organizations.field_assignment (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE logistics.field_visit ADD CONSTRAINT fk_field_visit_party_id FOREIGN KEY (tenant_id,party_id) REFERENCES organizations.party (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE logistics.temperature_reading ADD CONSTRAINT fk_temperature_reading_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE logistics.temperature_reading ADD CONSTRAINT fk_temperature_reading_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE logistics.temperature_reading ADD CONSTRAINT fk_temperature_reading_shipment_id FOREIGN KEY (tenant_id,shipment_id) REFERENCES fulfillment.shipment (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE "returns".return_case ADD CONSTRAINT fk_return_case_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE "returns".return_case ADD CONSTRAINT fk_return_case_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE "returns".return_case ADD CONSTRAINT fk_return_case_order_id FOREIGN KEY (tenant_id,order_id) REFERENCES commerce.sales_order (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE "returns".return_line ADD CONSTRAINT fk_return_line_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE "returns".return_line ADD CONSTRAINT fk_return_line_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE "returns".return_line ADD CONSTRAINT fk_return_line_case_id FOREIGN KEY (tenant_id,case_id) REFERENCES "returns".return_case (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE "returns".return_line ADD CONSTRAINT fk_return_line_shipment_line_id FOREIGN KEY (tenant_id,shipment_line_id) REFERENCES fulfillment.shipment_line (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE payments.merchant_account ADD CONSTRAINT fk_merchant_account_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE payments.merchant_account ADD CONSTRAINT fk_merchant_account_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE payments.merchant_account ADD CONSTRAINT fk_merchant_account_seller_id FOREIGN KEY (tenant_id,seller_id) REFERENCES organizations.party (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE payments.merchant_account ADD CONSTRAINT fk_merchant_account_provider_id FOREIGN KEY (provider_id) REFERENCES payments.provider (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE payments.payment_intent ADD CONSTRAINT fk_payment_intent_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE payments.payment_intent ADD CONSTRAINT fk_payment_intent_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE payments.payment_intent ADD CONSTRAINT fk_payment_intent_order_id FOREIGN KEY (tenant_id,order_id) REFERENCES commerce.sales_order (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE payments.payment_intent ADD CONSTRAINT fk_payment_intent_merchant_id FOREIGN KEY (tenant_id,merchant_id) REFERENCES payments.merchant_account (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE payments.webhook_inbox ADD CONSTRAINT fk_webhook_inbox_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE payments.webhook_inbox ADD CONSTRAINT fk_webhook_inbox_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE payments.webhook_inbox ADD CONSTRAINT fk_webhook_inbox_merchant_id FOREIGN KEY (tenant_id,merchant_id) REFERENCES payments.merchant_account (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE payments.payment_transaction ADD CONSTRAINT fk_payment_transaction_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE payments.payment_transaction ADD CONSTRAINT fk_payment_transaction_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE payments.payment_transaction ADD CONSTRAINT fk_payment_transaction_intent_id FOREIGN KEY (tenant_id,intent_id) REFERENCES payments.payment_intent (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE payments.payment_transaction ADD CONSTRAINT fk_payment_transaction_merchant_id FOREIGN KEY (tenant_id,merchant_id) REFERENCES payments.merchant_account (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE payments.payment_allocation ADD CONSTRAINT fk_payment_allocation_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE payments.payment_allocation ADD CONSTRAINT fk_payment_allocation_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE payments.payment_allocation ADD CONSTRAINT fk_payment_allocation_transaction_id FOREIGN KEY (tenant_id,transaction_id) REFERENCES payments.payment_transaction (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE payments.payment_allocation ADD CONSTRAINT fk_payment_allocation_invoice_id FOREIGN KEY (tenant_id,invoice_id) REFERENCES commerce.invoice (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE payments.refund ADD CONSTRAINT fk_refund_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE payments.refund ADD CONSTRAINT fk_refund_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE payments.refund ADD CONSTRAINT fk_refund_transaction_id FOREIGN KEY (tenant_id,transaction_id) REFERENCES payments.payment_transaction (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE payments.payout ADD CONSTRAINT fk_payout_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE payments.payout ADD CONSTRAINT fk_payout_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE payments.payout ADD CONSTRAINT fk_payout_merchant_id FOREIGN KEY (tenant_id,merchant_id) REFERENCES payments.merchant_account (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE payments.provider_settlement ADD CONSTRAINT fk_provider_settlement_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE payments.provider_settlement ADD CONSTRAINT fk_provider_settlement_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE payments.provider_settlement ADD CONSTRAINT fk_provider_settlement_merchant_id FOREIGN KEY (tenant_id,merchant_id) REFERENCES payments.merchant_account (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE credit.facility ADD CONSTRAINT fk_facility_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE credit.facility ADD CONSTRAINT fk_facility_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE credit.facility ADD CONSTRAINT fk_facility_buyer_id FOREIGN KEY (tenant_id,buyer_id) REFERENCES organizations.party (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE credit.facility ADD CONSTRAINT fk_facility_creditor_id FOREIGN KEY (tenant_id,creditor_id) REFERENCES organizations.party (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE credit.commitment ADD CONSTRAINT fk_commitment_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE credit.commitment ADD CONSTRAINT fk_commitment_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE credit.commitment ADD CONSTRAINT fk_commitment_facility_id FOREIGN KEY (tenant_id,facility_id) REFERENCES credit.facility (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE credit.commitment ADD CONSTRAINT fk_commitment_order_id FOREIGN KEY (tenant_id,order_id) REFERENCES commerce.sales_order (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE credit.receivable ADD CONSTRAINT fk_receivable_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE credit.receivable ADD CONSTRAINT fk_receivable_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE credit.receivable ADD CONSTRAINT fk_receivable_facility_id FOREIGN KEY (tenant_id,facility_id) REFERENCES credit.facility (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE credit.receivable ADD CONSTRAINT fk_receivable_invoice_id FOREIGN KEY (tenant_id,invoice_id) REFERENCES commerce.invoice (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE credit.installment_plan ADD CONSTRAINT fk_installment_plan_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE credit.installment_plan ADD CONSTRAINT fk_installment_plan_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE credit.installment_plan ADD CONSTRAINT fk_installment_plan_receivable_id FOREIGN KEY (tenant_id,receivable_id) REFERENCES credit.receivable (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE treasury.cash_session ADD CONSTRAINT fk_cash_session_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE treasury.cash_session ADD CONSTRAINT fk_cash_session_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE treasury.cash_session ADD CONSTRAINT fk_cash_session_collector_id FOREIGN KEY (tenant_id,collector_id) REFERENCES organizations.membership (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE treasury.cod_receipt ADD CONSTRAINT fk_cod_receipt_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE treasury.cod_receipt ADD CONSTRAINT fk_cod_receipt_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE treasury.cod_receipt ADD CONSTRAINT fk_cod_receipt_cash_session_id FOREIGN KEY (tenant_id,cash_session_id) REFERENCES treasury.cash_session (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE treasury.cod_receipt ADD CONSTRAINT fk_cod_receipt_shipment_id FOREIGN KEY (tenant_id,shipment_id) REFERENCES fulfillment.shipment (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE treasury.cod_receipt ADD CONSTRAINT fk_cod_receipt_invoice_id FOREIGN KEY (tenant_id,invoice_id) REFERENCES commerce.invoice (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE treasury.cash_handover ADD CONSTRAINT fk_cash_handover_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE treasury.cash_handover ADD CONSTRAINT fk_cash_handover_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE treasury.cash_handover ADD CONSTRAINT fk_cash_handover_cash_session_id FOREIGN KEY (tenant_id,cash_session_id) REFERENCES treasury.cash_session (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE treasury.cash_handover ADD CONSTRAINT fk_cash_handover_received_by FOREIGN KEY (tenant_id,received_by) REFERENCES organizations.membership (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE accounting.ledger ADD CONSTRAINT fk_ledger_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE accounting.ledger ADD CONSTRAINT fk_ledger_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE accounting.ledger ADD CONSTRAINT fk_ledger_legal_entity_id FOREIGN KEY (tenant_id,legal_entity_id) REFERENCES organizations.party (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE accounting.account ADD CONSTRAINT fk_account_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE accounting.account ADD CONSTRAINT fk_account_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE accounting.account ADD CONSTRAINT fk_account_ledger_id FOREIGN KEY (tenant_id,ledger_id) REFERENCES accounting.ledger (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE accounting.period ADD CONSTRAINT fk_period_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE accounting.period ADD CONSTRAINT fk_period_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE accounting.period ADD CONSTRAINT fk_period_ledger_id FOREIGN KEY (tenant_id,ledger_id) REFERENCES accounting.ledger (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE accounting.journal ADD CONSTRAINT fk_journal_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE accounting.journal ADD CONSTRAINT fk_journal_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE accounting.journal ADD CONSTRAINT fk_journal_ledger_id FOREIGN KEY (tenant_id,ledger_id) REFERENCES accounting.ledger (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE accounting.journal ADD CONSTRAINT fk_journal_period_id FOREIGN KEY (tenant_id,period_id) REFERENCES accounting.period (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE accounting.journal ADD CONSTRAINT fk_journal_maker_id FOREIGN KEY (tenant_id,maker_id) REFERENCES organizations.membership (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE accounting.journal ADD CONSTRAINT fk_journal_checker_id FOREIGN KEY (tenant_id,checker_id) REFERENCES organizations.membership (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE accounting.journal ADD CONSTRAINT fk_journal_reversed_journal_id FOREIGN KEY (tenant_id,reversed_journal_id) REFERENCES accounting.journal (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE accounting.journal_line ADD CONSTRAINT fk_journal_line_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE accounting.journal_line ADD CONSTRAINT fk_journal_line_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE accounting.journal_line ADD CONSTRAINT fk_journal_line_journal_id FOREIGN KEY (tenant_id,journal_id) REFERENCES accounting.journal (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE accounting.journal_line ADD CONSTRAINT fk_journal_line_account_id FOREIGN KEY (tenant_id,account_id) REFERENCES accounting.account (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE notifications.consent ADD CONSTRAINT fk_consent_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE notifications.consent ADD CONSTRAINT fk_consent_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE notifications.consent ADD CONSTRAINT fk_consent_membership_id FOREIGN KEY (tenant_id,membership_id) REFERENCES organizations.membership (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE notifications.template ADD CONSTRAINT fk_template_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE notifications.template ADD CONSTRAINT fk_template_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE notifications.message ADD CONSTRAINT fk_message_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE notifications.message ADD CONSTRAINT fk_message_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE notifications.message ADD CONSTRAINT fk_message_membership_id FOREIGN KEY (tenant_id,membership_id) REFERENCES organizations.membership (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE notifications.message ADD CONSTRAINT fk_message_template_id FOREIGN KEY (tenant_id,template_id) REFERENCES notifications.template (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE notifications.delivery_attempt ADD CONSTRAINT fk_delivery_attempt_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE notifications.delivery_attempt ADD CONSTRAINT fk_delivery_attempt_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE notifications.delivery_attempt ADD CONSTRAINT fk_delivery_attempt_message_id FOREIGN KEY (tenant_id,message_id) REFERENCES notifications.message (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE integrations.idempotency ADD CONSTRAINT fk_idempotency_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE integrations.idempotency ADD CONSTRAINT fk_idempotency_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE integrations.idempotency ADD CONSTRAINT fk_idempotency_membership_id FOREIGN KEY (tenant_id,membership_id) REFERENCES organizations.membership (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE integrations.outbox ADD CONSTRAINT fk_outbox_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE integrations.outbox ADD CONSTRAINT fk_outbox_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE integrations.consumer_receipt ADD CONSTRAINT fk_consumer_receipt_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE integrations.consumer_receipt ADD CONSTRAINT fk_consumer_receipt_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE integrations.consumer_receipt ADD CONSTRAINT fk_consumer_receipt_event_id FOREIGN KEY (tenant_id,event_id) REFERENCES integrations.outbox (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE integrations.sync_operation ADD CONSTRAINT fk_sync_operation_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE integrations.sync_operation ADD CONSTRAINT fk_sync_operation_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE integrations.sync_operation ADD CONSTRAINT fk_sync_operation_membership_id FOREIGN KEY (tenant_id,membership_id) REFERENCES organizations.membership (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE integrations.sync_operation ADD CONSTRAINT fk_sync_operation_device_id FOREIGN KEY (tenant_id,device_id) REFERENCES identity.device (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE integrations.bulk_job ADD CONSTRAINT fk_bulk_job_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE integrations.bulk_job ADD CONSTRAINT fk_bulk_job_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE integrations.bulk_job ADD CONSTRAINT fk_bulk_job_requested_by FOREIGN KEY (tenant_id,requested_by) REFERENCES organizations.membership (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE analytics.metric_snapshot ADD CONSTRAINT fk_metric_snapshot_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE analytics.metric_snapshot ADD CONSTRAINT fk_metric_snapshot_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE audit.event ADD CONSTRAINT fk_event_tenant_id FOREIGN KEY (tenant_id) REFERENCES organizations.tenant (id) ON DELETE RESTRICT ON UPDATE RESTRICT;
ALTER TABLE audit.event ADD CONSTRAINT fk_event_scope_id FOREIGN KEY (tenant_id,scope_id) REFERENCES organizations.scope (tenant_id,id) ON DELETE RESTRICT ON UPDATE RESTRICT;
CREATE INDEX ix_scope_parent_id ON organizations.scope (tenant_id,parent_id);
CREATE INDEX ix_membership_scope ON organizations.membership (tenant_id,scope_id);
CREATE INDEX ix_membership_principal_id ON organizations.membership (principal_id);
CREATE INDEX ix_role_scope ON "authorization".role (tenant_id,scope_id);
CREATE INDEX ix_role_permission_scope ON "authorization".role_permission (tenant_id,scope_id);
CREATE INDEX ix_role_permission_role_id ON "authorization".role_permission (tenant_id,role_id);
CREATE INDEX ix_assignment_scope ON "authorization".assignment (tenant_id,scope_id);
CREATE INDEX ix_assignment_membership_id ON "authorization".assignment (tenant_id,membership_id);
CREATE INDEX ix_assignment_role_id ON "authorization".assignment (tenant_id,role_id);
CREATE INDEX ix_assignment_assigned_scope_id ON "authorization".assignment (tenant_id,assigned_scope_id);
CREATE INDEX ix_device_scope ON identity.device (tenant_id,scope_id);
CREATE INDEX ix_device_membership_id ON identity.device (tenant_id,membership_id);
CREATE INDEX ix_session_scope ON identity.session (tenant_id,scope_id);
CREATE INDEX ix_session_membership_id ON identity.session (tenant_id,membership_id);
CREATE INDEX ix_session_device_id ON identity.session (tenant_id,device_id);
CREATE INDEX ix_district_governorate_id ON logistics.district (governorate_id);
CREATE INDEX ix_zone_scope ON logistics.zone (tenant_id,scope_id);
CREATE INDEX ix_zone_governorate_id ON logistics.zone (governorate_id);
CREATE INDEX ix_address_scope ON logistics.address (tenant_id,scope_id);
CREATE INDEX ix_address_governorate_id ON logistics.address (governorate_id);
CREATE INDEX ix_address_district_id ON logistics.address (district_id);
CREATE INDEX ix_shipping_tariff_scope ON logistics.shipping_tariff (tenant_id,scope_id);
CREATE INDEX ix_shipping_tariff_zone_id ON logistics.shipping_tariff (tenant_id,zone_id);
CREATE INDEX ix_shipping_tariff_origin_zone_id ON logistics.shipping_tariff (tenant_id,origin_zone_id);
CREATE INDEX ix_party_scope ON organizations.party (tenant_id,scope_id);
CREATE INDEX ix_branch_scope ON organizations.branch (tenant_id,scope_id);
CREATE INDEX ix_branch_party_id ON organizations.branch (tenant_id,party_id);
CREATE INDEX ix_branch_address_id ON organizations.branch (tenant_id,address_id);
CREATE INDEX ix_party_member_scope ON organizations.party_member (tenant_id,scope_id);
CREATE INDEX ix_party_member_party_id ON organizations.party_member (tenant_id,party_id);
CREATE INDEX ix_party_member_membership_id ON organizations.party_member (tenant_id,membership_id);
CREATE INDEX ix_territory_scope ON organizations.territory (tenant_id,scope_id);
CREATE INDEX ix_territory_zone_id ON organizations.territory (tenant_id,zone_id);
CREATE INDEX ix_field_assignment_scope ON organizations.field_assignment (tenant_id,scope_id);
CREATE INDEX ix_field_assignment_membership_id ON organizations.field_assignment (tenant_id,membership_id);
CREATE INDEX ix_field_assignment_territory_id ON organizations.field_assignment (tenant_id,territory_id);
CREATE INDEX ix_retailer_profile_scope ON organizations.retailer_profile (tenant_id,scope_id);
CREATE INDEX ix_retailer_profile_party_id ON organizations.retailer_profile (tenant_id,party_id);
CREATE INDEX ix_retailer_profile_address_id ON organizations.retailer_profile (tenant_id,address_id);
CREATE INDEX ix_supplier_profile_scope ON organizations.supplier_profile (tenant_id,scope_id);
CREATE INDEX ix_supplier_profile_party_id ON organizations.supplier_profile (tenant_id,party_id);
CREATE INDEX ix_kyc_case_scope ON compliance.kyc_case (tenant_id,scope_id);
CREATE INDEX ix_kyc_case_party_id ON compliance.kyc_case (tenant_id,party_id);
CREATE INDEX ix_kyc_case_decided_by ON compliance.kyc_case (tenant_id,decided_by);
CREATE INDEX ix_document_scope ON compliance.document (tenant_id,scope_id);
CREATE INDEX ix_document_party_id ON compliance.document (tenant_id,party_id);
CREATE INDEX ix_document_kyc_case_id ON compliance.document (tenant_id,kyc_case_id);
CREATE INDEX ix_kyc_decision_scope ON compliance.kyc_decision (tenant_id,scope_id);
CREATE INDEX ix_kyc_decision_case_id ON compliance.kyc_decision (tenant_id,case_id);
CREATE INDEX ix_kyc_decision_reviewer_id ON compliance.kyc_decision (tenant_id,reviewer_id);
CREATE INDEX ix_risk_case_scope ON compliance.risk_case (tenant_id,scope_id);
CREATE INDEX ix_risk_case_party_id ON compliance.risk_case (tenant_id,party_id);
CREATE INDEX ix_policy_scope ON compliance.policy (tenant_id,scope_id);
CREATE INDEX ix_approval_scope ON compliance.approval (tenant_id,scope_id);
CREATE INDEX ix_approval_maker_id ON compliance.approval (tenant_id,maker_id);
CREATE INDEX ix_approval_checker_id ON compliance.approval (tenant_id,checker_id);
CREATE INDEX ix_brand_scope ON catalog.brand (tenant_id,scope_id);
CREATE INDEX ix_category_scope ON catalog.category (tenant_id,scope_id);
CREATE INDEX ix_category_parent_id ON catalog.category (tenant_id,parent_id);
CREATE INDEX ix_product_scope ON catalog.product (tenant_id,scope_id);
CREATE INDEX ix_product_brand_id ON catalog.product (tenant_id,brand_id);
CREATE INDEX ix_product_category_id ON catalog.product (tenant_id,category_id);
CREATE INDEX ix_product_alias_scope ON catalog.product_alias (tenant_id,scope_id);
CREATE INDEX ix_product_alias_product_id ON catalog.product_alias (tenant_id,product_id);
CREATE INDEX ix_uom_scope ON catalog.uom (tenant_id,scope_id);
CREATE INDEX ix_uom_product_id ON catalog.uom (tenant_id,product_id);
CREATE INDEX ix_uom_parent_id ON catalog.uom (tenant_id,parent_id);
CREATE INDEX ix_product_license_scope ON catalog.product_license (tenant_id,scope_id);
CREATE INDEX ix_product_license_product_id ON catalog.product_license (tenant_id,product_id);
CREATE INDEX ix_product_license_party_id ON catalog.product_license (tenant_id,party_id);
CREATE INDEX ix_offer_scope ON pricing.offer (tenant_id,scope_id);
CREATE INDEX ix_offer_seller_id ON pricing.offer (tenant_id,seller_id);
CREATE INDEX ix_offer_product_id ON pricing.offer (tenant_id,product_id);
CREATE INDEX ix_offer_uom_id ON pricing.offer (tenant_id,uom_id);
CREATE INDEX ix_price_rule_scope ON pricing.price_rule (tenant_id,scope_id);
CREATE INDEX ix_price_rule_offer_id ON pricing.price_rule (tenant_id,offer_id);
CREATE INDEX ix_promotion_scope ON pricing.promotion (tenant_id,scope_id);
CREATE INDEX ix_promotion_seller_id ON pricing.promotion (tenant_id,seller_id);
CREATE INDEX ix_tax_rule_scope ON pricing.tax_rule (tenant_id,scope_id);
CREATE INDEX ix_tax_rule_category_id ON pricing.tax_rule (tenant_id,category_id);
CREATE INDEX ix_warehouse_scope ON inventory.warehouse (tenant_id,scope_id);
CREATE INDEX ix_warehouse_owner_id ON inventory.warehouse (tenant_id,owner_id);
CREATE INDEX ix_warehouse_branch_id ON inventory.warehouse (tenant_id,branch_id);
CREATE INDEX ix_warehouse_address_id ON inventory.warehouse (tenant_id,address_id);
CREATE INDEX ix_bin_scope ON inventory.bin (tenant_id,scope_id);
CREATE INDEX ix_bin_warehouse_id ON inventory.bin (tenant_id,warehouse_id);
CREATE INDEX ix_lot_scope ON inventory.lot (tenant_id,scope_id);
CREATE INDEX ix_lot_product_id ON inventory.lot (tenant_id,product_id);
CREATE INDEX ix_lot_owner_id ON inventory.lot (tenant_id,owner_id);
CREATE INDEX ix_stock_balance_scope ON inventory.stock_balance (tenant_id,scope_id);
CREATE INDEX ix_stock_balance_warehouse_id ON inventory.stock_balance (tenant_id,warehouse_id);
CREATE INDEX ix_stock_balance_bin_id ON inventory.stock_balance (tenant_id,bin_id);
CREATE INDEX ix_stock_balance_lot_id ON inventory.stock_balance (tenant_id,lot_id);
CREATE INDEX ix_stock_movement_scope ON inventory.stock_movement (tenant_id,scope_id);
CREATE INDEX ix_stock_movement_balance_id ON inventory.stock_movement (tenant_id,balance_id);
CREATE INDEX ix_reservation_scope ON inventory.reservation (tenant_id,scope_id);
CREATE INDEX ix_reservation_balance_id ON inventory.reservation (tenant_id,balance_id);
CREATE INDEX ix_reservation_order_line_id ON inventory.reservation (tenant_id,order_line_id);
CREATE INDEX ix_stock_transfer_scope ON inventory.stock_transfer (tenant_id,scope_id);
CREATE INDEX ix_stock_transfer_from_warehouse_id ON inventory.stock_transfer (tenant_id,from_warehouse_id);
CREATE INDEX ix_stock_transfer_to_warehouse_id ON inventory.stock_transfer (tenant_id,to_warehouse_id);
CREATE INDEX ix_transfer_line_scope ON inventory.transfer_line (tenant_id,scope_id);
CREATE INDEX ix_transfer_line_transfer_id ON inventory.transfer_line (tenant_id,transfer_id);
CREATE INDEX ix_transfer_line_lot_id ON inventory.transfer_line (tenant_id,lot_id);
CREATE INDEX ix_stocktake_scope ON inventory.stocktake (tenant_id,scope_id);
CREATE INDEX ix_stocktake_warehouse_id ON inventory.stocktake (tenant_id,warehouse_id);
CREATE INDEX ix_stocktake_line_scope ON inventory.stocktake_line (tenant_id,scope_id);
CREATE INDEX ix_stocktake_line_stocktake_id ON inventory.stocktake_line (tenant_id,stocktake_id);
CREATE INDEX ix_stocktake_line_balance_id ON inventory.stocktake_line (tenant_id,balance_id);
CREATE INDEX ix_purchase_order_scope ON procurement.purchase_order (tenant_id,scope_id);
CREATE INDEX ix_purchase_order_supplier_id ON procurement.purchase_order (tenant_id,supplier_id);
CREATE INDEX ix_purchase_order_buyer_id ON procurement.purchase_order (tenant_id,buyer_id);
CREATE INDEX ix_purchase_line_scope ON procurement.purchase_line (tenant_id,scope_id);
CREATE INDEX ix_purchase_line_purchase_order_id ON procurement.purchase_line (tenant_id,purchase_order_id);
CREATE INDEX ix_purchase_line_product_id ON procurement.purchase_line (tenant_id,product_id);
CREATE INDEX ix_purchase_line_uom_id ON procurement.purchase_line (tenant_id,uom_id);
CREATE INDEX ix_goods_receipt_scope ON procurement.goods_receipt (tenant_id,scope_id);
CREATE INDEX ix_goods_receipt_purchase_order_id ON procurement.goods_receipt (tenant_id,purchase_order_id);
CREATE INDEX ix_goods_receipt_warehouse_id ON procurement.goods_receipt (tenant_id,warehouse_id);
CREATE INDEX ix_receipt_line_scope ON procurement.receipt_line (tenant_id,scope_id);
CREATE INDEX ix_receipt_line_receipt_id ON procurement.receipt_line (tenant_id,receipt_id);
CREATE INDEX ix_receipt_line_purchase_line_id ON procurement.receipt_line (tenant_id,purchase_line_id);
CREATE INDEX ix_receipt_line_lot_id ON procurement.receipt_line (tenant_id,lot_id);
CREATE INDEX ix_supplier_bill_scope ON procurement.supplier_bill (tenant_id,scope_id);
CREATE INDEX ix_supplier_bill_purchase_order_id ON procurement.supplier_bill (tenant_id,purchase_order_id);
CREATE INDEX ix_supplier_bill_supplier_id ON procurement.supplier_bill (tenant_id,supplier_id);
CREATE INDEX ix_landed_cost_scope ON procurement.landed_cost (tenant_id,scope_id);
CREATE INDEX ix_landed_cost_receipt_id ON procurement.landed_cost (tenant_id,receipt_id);
CREATE INDEX ix_fx_rate_scope ON treasury.fx_rate (tenant_id,scope_id);
CREATE INDEX ix_cart_scope ON commerce.cart (tenant_id,scope_id);
CREATE INDEX ix_cart_buyer_id ON commerce.cart (tenant_id,buyer_id);
CREATE INDEX ix_cart_line_scope ON commerce.cart_line (tenant_id,scope_id);
CREATE INDEX ix_cart_line_cart_id ON commerce.cart_line (tenant_id,cart_id);
CREATE INDEX ix_cart_line_offer_id ON commerce.cart_line (tenant_id,offer_id);
CREATE INDEX ix_quote_scope ON commerce.quote (tenant_id,scope_id);
CREATE INDEX ix_quote_buyer_id ON commerce.quote (tenant_id,buyer_id);
CREATE INDEX ix_quote_seller_id ON commerce.quote (tenant_id,seller_id);
CREATE INDEX ix_quote_fx_rate_id ON commerce.quote (tenant_id,fx_rate_id);
CREATE INDEX ix_quote_line_scope ON commerce.quote_line (tenant_id,scope_id);
CREATE INDEX ix_quote_line_quote_id ON commerce.quote_line (tenant_id,quote_id);
CREATE INDEX ix_quote_line_offer_id ON commerce.quote_line (tenant_id,offer_id);
CREATE INDEX ix_quote_line_uom_id ON commerce.quote_line (tenant_id,uom_id);
CREATE INDEX ix_purchase_group_scope ON commerce.purchase_group (tenant_id,scope_id);
CREATE INDEX ix_purchase_group_buyer_id ON commerce.purchase_group (tenant_id,buyer_id);
CREATE INDEX ix_sales_order_scope ON commerce.sales_order (tenant_id,scope_id);
CREATE INDEX ix_sales_order_group_id ON commerce.sales_order (tenant_id,group_id);
CREATE INDEX ix_sales_order_quote_id ON commerce.sales_order (tenant_id,quote_id);
CREATE INDEX ix_sales_order_buyer_id ON commerce.sales_order (tenant_id,buyer_id);
CREATE INDEX ix_sales_order_seller_id ON commerce.sales_order (tenant_id,seller_id);
CREATE INDEX ix_order_line_scope ON commerce.order_line (tenant_id,scope_id);
CREATE INDEX ix_order_line_order_id ON commerce.order_line (tenant_id,order_id);
CREATE INDEX ix_order_line_quote_line_id ON commerce.order_line (tenant_id,quote_line_id);
CREATE INDEX ix_order_line_product_id ON commerce.order_line (tenant_id,product_id);
CREATE INDEX ix_order_line_uom_id ON commerce.order_line (tenant_id,uom_id);
CREATE INDEX ix_order_amendment_scope ON commerce.order_amendment (tenant_id,scope_id);
CREATE INDEX ix_order_amendment_order_id ON commerce.order_amendment (tenant_id,order_id);
CREATE INDEX ix_rfq_scope ON commerce.rfq (tenant_id,scope_id);
CREATE INDEX ix_rfq_buyer_id ON commerce.rfq (tenant_id,buyer_id);
CREATE INDEX ix_rfq_seller_id ON commerce.rfq (tenant_id,seller_id);
CREATE INDEX ix_rfq_offer_scope ON commerce.rfq_offer (tenant_id,scope_id);
CREATE INDEX ix_rfq_offer_rfq_id ON commerce.rfq_offer (tenant_id,rfq_id);
CREATE INDEX ix_rfq_offer_quote_id ON commerce.rfq_offer (tenant_id,quote_id);
CREATE INDEX ix_invoice_scope ON commerce.invoice (tenant_id,scope_id);
CREATE INDEX ix_invoice_order_id ON commerce.invoice (tenant_id,order_id);
CREATE INDEX ix_invoice_seller_id ON commerce.invoice (tenant_id,seller_id);
CREATE INDEX ix_invoice_buyer_id ON commerce.invoice (tenant_id,buyer_id);
CREATE INDEX ix_invoice_fx_rate_id ON commerce.invoice (tenant_id,fx_rate_id);
CREATE INDEX ix_invoice_line_scope ON commerce.invoice_line (tenant_id,scope_id);
CREATE INDEX ix_invoice_line_invoice_id ON commerce.invoice_line (tenant_id,invoice_id);
CREATE INDEX ix_invoice_line_order_line_id ON commerce.invoice_line (tenant_id,order_line_id);
CREATE INDEX ix_credit_note_scope ON commerce.credit_note (tenant_id,scope_id);
CREATE INDEX ix_credit_note_invoice_id ON commerce.credit_note (tenant_id,invoice_id);
CREATE INDEX ix_shipment_scope ON fulfillment.shipment (tenant_id,scope_id);
CREATE INDEX ix_shipment_order_id ON fulfillment.shipment (tenant_id,order_id);
CREATE INDEX ix_shipment_warehouse_id ON fulfillment.shipment (tenant_id,warehouse_id);
CREATE INDEX ix_shipment_address_id ON fulfillment.shipment (tenant_id,address_id);
CREATE INDEX ix_shipment_driver_id ON fulfillment.shipment (tenant_id,driver_id);
CREATE INDEX ix_shipment_courier_id ON fulfillment.shipment (tenant_id,courier_id);
CREATE INDEX ix_shipment_line_scope ON fulfillment.shipment_line (tenant_id,scope_id);
CREATE INDEX ix_shipment_line_shipment_id ON fulfillment.shipment_line (tenant_id,shipment_id);
CREATE INDEX ix_shipment_line_order_line_id ON fulfillment.shipment_line (tenant_id,order_line_id);
CREATE INDEX ix_shipment_line_lot_id ON fulfillment.shipment_line (tenant_id,lot_id);
CREATE INDEX ix_pick_task_scope ON fulfillment.pick_task (tenant_id,scope_id);
CREATE INDEX ix_pick_task_shipment_id ON fulfillment.pick_task (tenant_id,shipment_id);
CREATE INDEX ix_pick_task_reservation_id ON fulfillment.pick_task (tenant_id,reservation_id);
CREATE INDEX ix_pick_task_assignee_id ON fulfillment.pick_task (tenant_id,assignee_id);
CREATE INDEX ix_delivery_proof_scope ON fulfillment.delivery_proof (tenant_id,scope_id);
CREATE INDEX ix_delivery_proof_shipment_id ON fulfillment.delivery_proof (tenant_id,shipment_id);
CREATE INDEX ix_vehicle_scope ON logistics.vehicle (tenant_id,scope_id);
CREATE INDEX ix_route_plan_scope ON logistics.route_plan (tenant_id,scope_id);
CREATE INDEX ix_route_plan_territory_id ON logistics.route_plan (tenant_id,territory_id);
CREATE INDEX ix_route_plan_driver_id ON logistics.route_plan (tenant_id,driver_id);
CREATE INDEX ix_route_plan_vehicle_id ON logistics.route_plan (tenant_id,vehicle_id);
CREATE INDEX ix_route_stop_scope ON logistics.route_stop (tenant_id,scope_id);
CREATE INDEX ix_route_stop_route_id ON logistics.route_stop (tenant_id,route_id);
CREATE INDEX ix_route_stop_address_id ON logistics.route_stop (tenant_id,address_id);
CREATE INDEX ix_route_stop_shipment_id ON logistics.route_stop (tenant_id,shipment_id);
CREATE INDEX ix_field_visit_scope ON logistics.field_visit (tenant_id,scope_id);
CREATE INDEX ix_field_visit_assignment_id ON logistics.field_visit (tenant_id,assignment_id);
CREATE INDEX ix_field_visit_party_id ON logistics.field_visit (tenant_id,party_id);
CREATE INDEX ix_temperature_reading_scope ON logistics.temperature_reading (tenant_id,scope_id);
CREATE INDEX ix_temperature_reading_shipment_id ON logistics.temperature_reading (tenant_id,shipment_id);
CREATE INDEX ix_return_case_scope ON "returns".return_case (tenant_id,scope_id);
CREATE INDEX ix_return_case_order_id ON "returns".return_case (tenant_id,order_id);
CREATE INDEX ix_return_line_scope ON "returns".return_line (tenant_id,scope_id);
CREATE INDEX ix_return_line_case_id ON "returns".return_line (tenant_id,case_id);
CREATE INDEX ix_return_line_shipment_line_id ON "returns".return_line (tenant_id,shipment_line_id);
CREATE INDEX ix_merchant_account_scope ON payments.merchant_account (tenant_id,scope_id);
CREATE INDEX ix_merchant_account_seller_id ON payments.merchant_account (tenant_id,seller_id);
CREATE INDEX ix_merchant_account_provider_id ON payments.merchant_account (provider_id);
CREATE INDEX ix_payment_intent_scope ON payments.payment_intent (tenant_id,scope_id);
CREATE INDEX ix_payment_intent_order_id ON payments.payment_intent (tenant_id,order_id);
CREATE INDEX ix_payment_intent_merchant_id ON payments.payment_intent (tenant_id,merchant_id);
CREATE INDEX ix_webhook_inbox_scope ON payments.webhook_inbox (tenant_id,scope_id);
CREATE INDEX ix_webhook_inbox_merchant_id ON payments.webhook_inbox (tenant_id,merchant_id);
CREATE INDEX ix_payment_transaction_scope ON payments.payment_transaction (tenant_id,scope_id);
CREATE INDEX ix_payment_transaction_intent_id ON payments.payment_transaction (tenant_id,intent_id);
CREATE INDEX ix_payment_transaction_merchant_id ON payments.payment_transaction (tenant_id,merchant_id);
CREATE INDEX ix_payment_allocation_scope ON payments.payment_allocation (tenant_id,scope_id);
CREATE INDEX ix_payment_allocation_transaction_id ON payments.payment_allocation (tenant_id,transaction_id);
CREATE INDEX ix_payment_allocation_invoice_id ON payments.payment_allocation (tenant_id,invoice_id);
CREATE INDEX ix_refund_scope ON payments.refund (tenant_id,scope_id);
CREATE INDEX ix_refund_transaction_id ON payments.refund (tenant_id,transaction_id);
CREATE INDEX ix_payout_scope ON payments.payout (tenant_id,scope_id);
CREATE INDEX ix_payout_merchant_id ON payments.payout (tenant_id,merchant_id);
CREATE INDEX ix_provider_settlement_scope ON payments.provider_settlement (tenant_id,scope_id);
CREATE INDEX ix_provider_settlement_merchant_id ON payments.provider_settlement (tenant_id,merchant_id);
CREATE INDEX ix_facility_scope ON credit.facility (tenant_id,scope_id);
CREATE INDEX ix_facility_buyer_id ON credit.facility (tenant_id,buyer_id);
CREATE INDEX ix_facility_creditor_id ON credit.facility (tenant_id,creditor_id);
CREATE INDEX ix_commitment_scope ON credit.commitment (tenant_id,scope_id);
CREATE INDEX ix_commitment_facility_id ON credit.commitment (tenant_id,facility_id);
CREATE INDEX ix_commitment_order_id ON credit.commitment (tenant_id,order_id);
CREATE INDEX ix_receivable_scope ON credit.receivable (tenant_id,scope_id);
CREATE INDEX ix_receivable_facility_id ON credit.receivable (tenant_id,facility_id);
CREATE INDEX ix_receivable_invoice_id ON credit.receivable (tenant_id,invoice_id);
CREATE INDEX ix_installment_plan_scope ON credit.installment_plan (tenant_id,scope_id);
CREATE INDEX ix_installment_plan_receivable_id ON credit.installment_plan (tenant_id,receivable_id);
CREATE INDEX ix_cash_session_scope ON treasury.cash_session (tenant_id,scope_id);
CREATE INDEX ix_cash_session_collector_id ON treasury.cash_session (tenant_id,collector_id);
CREATE INDEX ix_cod_receipt_scope ON treasury.cod_receipt (tenant_id,scope_id);
CREATE INDEX ix_cod_receipt_cash_session_id ON treasury.cod_receipt (tenant_id,cash_session_id);
CREATE INDEX ix_cod_receipt_shipment_id ON treasury.cod_receipt (tenant_id,shipment_id);
CREATE INDEX ix_cod_receipt_invoice_id ON treasury.cod_receipt (tenant_id,invoice_id);
CREATE INDEX ix_cash_handover_scope ON treasury.cash_handover (tenant_id,scope_id);
CREATE INDEX ix_cash_handover_cash_session_id ON treasury.cash_handover (tenant_id,cash_session_id);
CREATE INDEX ix_cash_handover_received_by ON treasury.cash_handover (tenant_id,received_by);
CREATE INDEX ix_ledger_scope ON accounting.ledger (tenant_id,scope_id);
CREATE INDEX ix_ledger_legal_entity_id ON accounting.ledger (tenant_id,legal_entity_id);
CREATE INDEX ix_account_scope ON accounting.account (tenant_id,scope_id);
CREATE INDEX ix_account_ledger_id ON accounting.account (tenant_id,ledger_id);
CREATE INDEX ix_period_scope ON accounting.period (tenant_id,scope_id);
CREATE INDEX ix_period_ledger_id ON accounting.period (tenant_id,ledger_id);
CREATE INDEX ix_journal_scope ON accounting.journal (tenant_id,scope_id);
CREATE INDEX ix_journal_ledger_id ON accounting.journal (tenant_id,ledger_id);
CREATE INDEX ix_journal_period_id ON accounting.journal (tenant_id,period_id);
CREATE INDEX ix_journal_maker_id ON accounting.journal (tenant_id,maker_id);
CREATE INDEX ix_journal_checker_id ON accounting.journal (tenant_id,checker_id);
CREATE INDEX ix_journal_reversed_journal_id ON accounting.journal (tenant_id,reversed_journal_id);
CREATE INDEX ix_journal_line_scope ON accounting.journal_line (tenant_id,scope_id);
CREATE INDEX ix_journal_line_journal_id ON accounting.journal_line (tenant_id,journal_id);
CREATE INDEX ix_journal_line_account_id ON accounting.journal_line (tenant_id,account_id);
CREATE INDEX ix_consent_scope ON notifications.consent (tenant_id,scope_id);
CREATE INDEX ix_consent_membership_id ON notifications.consent (tenant_id,membership_id);
CREATE INDEX ix_template_scope ON notifications.template (tenant_id,scope_id);
CREATE INDEX ix_message_scope ON notifications.message (tenant_id,scope_id);
CREATE INDEX ix_message_membership_id ON notifications.message (tenant_id,membership_id);
CREATE INDEX ix_message_template_id ON notifications.message (tenant_id,template_id);
CREATE INDEX ix_delivery_attempt_scope ON notifications.delivery_attempt (tenant_id,scope_id);
CREATE INDEX ix_delivery_attempt_message_id ON notifications.delivery_attempt (tenant_id,message_id);
CREATE INDEX ix_idempotency_scope ON integrations.idempotency (tenant_id,scope_id);
CREATE INDEX ix_idempotency_membership_id ON integrations.idempotency (tenant_id,membership_id);
CREATE INDEX ix_outbox_scope ON integrations.outbox (tenant_id,scope_id);
CREATE INDEX ix_consumer_receipt_scope ON integrations.consumer_receipt (tenant_id,scope_id);
CREATE INDEX ix_consumer_receipt_event_id ON integrations.consumer_receipt (tenant_id,event_id);
CREATE INDEX ix_sync_operation_scope ON integrations.sync_operation (tenant_id,scope_id);
CREATE INDEX ix_sync_operation_membership_id ON integrations.sync_operation (tenant_id,membership_id);
CREATE INDEX ix_sync_operation_device_id ON integrations.sync_operation (tenant_id,device_id);
CREATE INDEX ix_bulk_job_scope ON integrations.bulk_job (tenant_id,scope_id);
CREATE INDEX ix_bulk_job_requested_by ON integrations.bulk_job (tenant_id,requested_by);
CREATE INDEX ix_metric_snapshot_scope ON analytics.metric_snapshot (tenant_id,scope_id);
CREATE INDEX ix_event_scope ON audit.event (tenant_id,scope_id);
CREATE INDEX ix_product_search ON catalog.product USING gin (search_text gin_trgm_ops);
CREATE INDEX ix_alias_search ON catalog.product_alias USING gin (normalized gin_trgm_ops);
CREATE INDEX ix_address_point ON logistics.address USING gist(point);
CREATE INDEX ix_zone_boundary ON logistics.zone USING gist(boundary);
CREATE INDEX ix_lot_fefo ON inventory.lot(tenant_id,product_id,expiry_date) WHERE archived_at IS NULL;
CREATE INDEX ix_outbox_pending ON integrations.outbox(created_at) WHERE published_at IS NULL;
CREATE INDEX ix_receivable_due ON credit.receivable(tenant_id,facility_id,due_at) WHERE outstanding_minor>0;
CREATE UNIQUE INDEX uq_payment_provider_no_merchant ON payments.payment_transaction(tenant_id,provider_ref) WHERE merchant_id IS NULL;
ALTER TABLE payments.webhook_inbox ADD CONSTRAINT fk_webhook_verified_intent FOREIGN KEY(tenant_id,verified_intent_id) REFERENCES payments.payment_intent(tenant_id,id);
COMMIT;
