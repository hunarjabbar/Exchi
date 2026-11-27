-- DropForeignKey
ALTER TABLE "catalog"."uom" DROP CONSTRAINT "uom_tenant_id_product_id_parent_id_fkey";

-- DropForeignKey
ALTER TABLE "commerce"."invoice" DROP CONSTRAINT "invoice_tenant_id_buyer_id_seller_id_order_id_fkey";

-- DropForeignKey
ALTER TABLE "commerce"."order_line" DROP CONSTRAINT "order_line_tenant_id_product_id_uom_id_fkey";

-- DropForeignKey
ALTER TABLE "commerce"."sales_order" DROP CONSTRAINT "sales_order_tenant_id_buyer_id_seller_id_quote_id_fkey";

-- DropForeignKey
ALTER TABLE "inventory"."stock_balance" DROP CONSTRAINT "stock_balance_tenant_id_warehouse_id_bin_id_fkey";

-- DropForeignKey
ALTER TABLE "logistics"."address" DROP CONSTRAINT "address_governorate_id_district_id_fkey";

-- DropForeignKey
ALTER TABLE "pricing"."offer" DROP CONSTRAINT "offer_tenant_id_product_id_uom_id_fkey";

-- DropForeignKey
ALTER TABLE "procurement"."purchase_line" DROP CONSTRAINT "purchase_line_tenant_id_product_id_uom_id_fkey";

-- DropIndex
DROP INDEX "accounting"."ix_account_ledger_id";

-- DropIndex
DROP INDEX "accounting"."ix_account_scope";

-- DropIndex
DROP INDEX "accounting"."ix_journal_checker_id";

-- DropIndex
DROP INDEX "accounting"."ix_journal_ledger_id";

-- DropIndex
DROP INDEX "accounting"."ix_journal_maker_id";

-- DropIndex
DROP INDEX "accounting"."ix_journal_period_id";

-- DropIndex
DROP INDEX "accounting"."ix_journal_reversed_journal_id";

-- DropIndex
DROP INDEX "accounting"."ix_journal_scope";

-- DropIndex
DROP INDEX "accounting"."ix_journal_line_account_id";

-- DropIndex
DROP INDEX "accounting"."ix_journal_line_journal_id";

-- DropIndex
DROP INDEX "accounting"."ix_journal_line_scope";

-- DropIndex
DROP INDEX "accounting"."ix_ledger_legal_entity_id";

-- DropIndex
DROP INDEX "accounting"."ix_ledger_scope";

-- DropIndex
DROP INDEX "accounting"."ix_period_ledger_id";

-- DropIndex
DROP INDEX "accounting"."ix_period_scope";

-- DropIndex
DROP INDEX "analytics"."ix_metric_snapshot_scope";

-- DropIndex
DROP INDEX "audit"."ix_event_scope";

-- DropIndex
DROP INDEX "authorization"."ix_assignment_assigned_scope_id";

-- DropIndex
DROP INDEX "authorization"."ix_assignment_membership_id";

-- DropIndex
DROP INDEX "authorization"."ix_assignment_role_id";

-- DropIndex
DROP INDEX "authorization"."ix_assignment_scope";

-- DropIndex
DROP INDEX "authorization"."ix_role_scope";

-- DropIndex
DROP INDEX "authorization"."ix_role_permission_role_id";

-- DropIndex
DROP INDEX "authorization"."ix_role_permission_scope";

-- DropIndex
DROP INDEX "catalog"."ix_brand_scope";

-- DropIndex
DROP INDEX "catalog"."ix_category_parent_id";

-- DropIndex
DROP INDEX "catalog"."ix_category_scope";

-- DropIndex
DROP INDEX "catalog"."ix_product_brand_id";

-- DropIndex
DROP INDEX "catalog"."ix_product_category_id";

-- DropIndex
DROP INDEX "catalog"."ix_product_scope";

-- DropIndex
DROP INDEX "catalog"."ix_product_search";

-- DropIndex
DROP INDEX "catalog"."ix_alias_search";

-- DropIndex
DROP INDEX "catalog"."ix_product_alias_product_id";

-- DropIndex
DROP INDEX "catalog"."ix_product_alias_scope";

-- DropIndex
DROP INDEX "catalog"."ix_product_license_party_id";

-- DropIndex
DROP INDEX "catalog"."ix_product_license_product_id";

-- DropIndex
DROP INDEX "catalog"."ix_product_license_scope";

-- DropIndex
DROP INDEX "catalog"."ix_uom_parent_id";

-- DropIndex
DROP INDEX "catalog"."ix_uom_product_id";

-- DropIndex
DROP INDEX "catalog"."ix_uom_scope";

-- DropIndex
DROP INDEX "catalog"."uom_tenant_id_product_id_id_key";

-- DropIndex
DROP INDEX "commerce"."ix_cart_buyer_id";

-- DropIndex
DROP INDEX "commerce"."ix_cart_scope";

-- DropIndex
DROP INDEX "commerce"."ix_cart_line_cart_id";

-- DropIndex
DROP INDEX "commerce"."ix_cart_line_offer_id";

-- DropIndex
DROP INDEX "commerce"."ix_cart_line_scope";

-- DropIndex
DROP INDEX "commerce"."ix_credit_note_invoice_id";

-- DropIndex
DROP INDEX "commerce"."ix_credit_note_scope";

-- DropIndex
DROP INDEX "commerce"."ix_invoice_buyer_id";

-- DropIndex
DROP INDEX "commerce"."ix_invoice_fx_rate_id";

-- DropIndex
DROP INDEX "commerce"."ix_invoice_order_id";

-- DropIndex
DROP INDEX "commerce"."ix_invoice_scope";

-- DropIndex
DROP INDEX "commerce"."ix_invoice_seller_id";

-- DropIndex
DROP INDEX "commerce"."ix_invoice_line_invoice_id";

-- DropIndex
DROP INDEX "commerce"."ix_invoice_line_order_line_id";

-- DropIndex
DROP INDEX "commerce"."ix_invoice_line_scope";

-- DropIndex
DROP INDEX "commerce"."ix_order_amendment_order_id";

-- DropIndex
DROP INDEX "commerce"."ix_order_amendment_scope";

-- DropIndex
DROP INDEX "commerce"."ix_order_line_order_id";

-- DropIndex
DROP INDEX "commerce"."ix_order_line_product_id";

-- DropIndex
DROP INDEX "commerce"."ix_order_line_quote_line_id";

-- DropIndex
DROP INDEX "commerce"."ix_order_line_scope";

-- DropIndex
DROP INDEX "commerce"."ix_order_line_uom_id";

-- DropIndex
DROP INDEX "commerce"."ix_purchase_group_buyer_id";

-- DropIndex
DROP INDEX "commerce"."ix_purchase_group_scope";

-- DropIndex
DROP INDEX "commerce"."ix_quote_buyer_id";

-- DropIndex
DROP INDEX "commerce"."ix_quote_fx_rate_id";

-- DropIndex
DROP INDEX "commerce"."ix_quote_scope";

-- DropIndex
DROP INDEX "commerce"."ix_quote_seller_id";

-- DropIndex
DROP INDEX "commerce"."quote_tenant_id_buyer_id_seller_id_id_key";

-- DropIndex
DROP INDEX "commerce"."ix_quote_line_offer_id";

-- DropIndex
DROP INDEX "commerce"."ix_quote_line_quote_id";

-- DropIndex
DROP INDEX "commerce"."ix_quote_line_scope";

-- DropIndex
DROP INDEX "commerce"."ix_quote_line_uom_id";

-- DropIndex
DROP INDEX "commerce"."ix_rfq_buyer_id";

-- DropIndex
DROP INDEX "commerce"."ix_rfq_scope";

-- DropIndex
DROP INDEX "commerce"."ix_rfq_seller_id";

-- DropIndex
DROP INDEX "commerce"."ix_rfq_offer_quote_id";

-- DropIndex
DROP INDEX "commerce"."ix_rfq_offer_rfq_id";

-- DropIndex
DROP INDEX "commerce"."ix_rfq_offer_scope";

-- DropIndex
DROP INDEX "commerce"."ix_sales_order_buyer_id";

-- DropIndex
DROP INDEX "commerce"."ix_sales_order_group_id";

-- DropIndex
DROP INDEX "commerce"."ix_sales_order_quote_id";

-- DropIndex
DROP INDEX "commerce"."ix_sales_order_scope";

-- DropIndex
DROP INDEX "commerce"."ix_sales_order_seller_id";

-- DropIndex
DROP INDEX "commerce"."sales_order_tenant_id_buyer_id_seller_id_id_key";

-- DropIndex
DROP INDEX "compliance"."ix_approval_checker_id";

-- DropIndex
DROP INDEX "compliance"."ix_approval_maker_id";

-- DropIndex
DROP INDEX "compliance"."ix_approval_scope";

-- DropIndex
DROP INDEX "compliance"."ix_document_kyc_case_id";

-- DropIndex
DROP INDEX "compliance"."ix_document_party_id";

-- DropIndex
DROP INDEX "compliance"."ix_document_scope";

-- DropIndex
DROP INDEX "compliance"."ix_kyc_case_decided_by";

-- DropIndex
DROP INDEX "compliance"."ix_kyc_case_party_id";

-- DropIndex
DROP INDEX "compliance"."ix_kyc_case_scope";

-- DropIndex
DROP INDEX "compliance"."ix_kyc_decision_case_id";

-- DropIndex
DROP INDEX "compliance"."ix_kyc_decision_reviewer_id";

-- DropIndex
DROP INDEX "compliance"."ix_kyc_decision_scope";

-- DropIndex
DROP INDEX "compliance"."ix_policy_scope";

-- DropIndex
DROP INDEX "compliance"."ix_risk_case_party_id";

-- DropIndex
DROP INDEX "compliance"."ix_risk_case_scope";

-- DropIndex
DROP INDEX "credit"."ix_commitment_facility_id";

-- DropIndex
DROP INDEX "credit"."ix_commitment_order_id";

-- DropIndex
DROP INDEX "credit"."ix_commitment_scope";

-- DropIndex
DROP INDEX "credit"."ix_facility_buyer_id";

-- DropIndex
DROP INDEX "credit"."ix_facility_creditor_id";

-- DropIndex
DROP INDEX "credit"."ix_facility_scope";

-- DropIndex
DROP INDEX "credit"."ix_installment_plan_receivable_id";

-- DropIndex
DROP INDEX "credit"."ix_installment_plan_scope";

-- DropIndex
DROP INDEX "credit"."ix_receivable_facility_id";

-- DropIndex
DROP INDEX "credit"."ix_receivable_invoice_id";

-- DropIndex
DROP INDEX "credit"."ix_receivable_scope";

-- DropIndex
DROP INDEX "fulfillment"."ix_delivery_proof_scope";

-- DropIndex
DROP INDEX "fulfillment"."ix_delivery_proof_shipment_id";

-- DropIndex
DROP INDEX "fulfillment"."ix_pick_task_assignee_id";

-- DropIndex
DROP INDEX "fulfillment"."ix_pick_task_reservation_id";

-- DropIndex
DROP INDEX "fulfillment"."ix_pick_task_scope";

-- DropIndex
DROP INDEX "fulfillment"."ix_pick_task_shipment_id";

-- DropIndex
DROP INDEX "fulfillment"."ix_shipment_address_id";

-- DropIndex
DROP INDEX "fulfillment"."ix_shipment_courier_id";

-- DropIndex
DROP INDEX "fulfillment"."ix_shipment_driver_id";

-- DropIndex
DROP INDEX "fulfillment"."ix_shipment_order_id";

-- DropIndex
DROP INDEX "fulfillment"."ix_shipment_scope";

-- DropIndex
DROP INDEX "fulfillment"."ix_shipment_warehouse_id";

-- DropIndex
DROP INDEX "fulfillment"."ix_shipment_line_lot_id";

-- DropIndex
DROP INDEX "fulfillment"."ix_shipment_line_order_line_id";

-- DropIndex
DROP INDEX "fulfillment"."ix_shipment_line_scope";

-- DropIndex
DROP INDEX "fulfillment"."ix_shipment_line_shipment_id";

-- DropIndex
DROP INDEX "identity"."ix_device_membership_id";

-- DropIndex
DROP INDEX "identity"."ix_device_scope";

-- DropIndex
DROP INDEX "identity"."ix_session_device_id";

-- DropIndex
DROP INDEX "identity"."ix_session_membership_id";

-- DropIndex
DROP INDEX "identity"."ix_session_scope";

-- DropIndex
DROP INDEX "integrations"."ix_bulk_job_requested_by";

-- DropIndex
DROP INDEX "integrations"."ix_bulk_job_scope";

-- DropIndex
DROP INDEX "integrations"."ix_consumer_receipt_event_id";

-- DropIndex
DROP INDEX "integrations"."ix_consumer_receipt_scope";

-- DropIndex
DROP INDEX "integrations"."ix_idempotency_membership_id";

-- DropIndex
DROP INDEX "integrations"."ix_idempotency_scope";

-- DropIndex
DROP INDEX "integrations"."ix_outbox_scope";

-- DropIndex
DROP INDEX "integrations"."ix_sync_operation_device_id";

-- DropIndex
DROP INDEX "integrations"."ix_sync_operation_membership_id";

-- DropIndex
DROP INDEX "integrations"."ix_sync_operation_scope";

-- DropIndex
DROP INDEX "inventory"."bin_tenant_id_warehouse_id_id_key";

-- DropIndex
DROP INDEX "inventory"."ix_bin_scope";

-- DropIndex
DROP INDEX "inventory"."ix_bin_warehouse_id";

-- DropIndex
DROP INDEX "inventory"."ix_lot_owner_id";

-- DropIndex
DROP INDEX "inventory"."ix_lot_product_id";

-- DropIndex
DROP INDEX "inventory"."ix_lot_scope";

-- DropIndex
DROP INDEX "inventory"."ix_reservation_balance_id";

-- DropIndex
DROP INDEX "inventory"."ix_reservation_order_line_id";

-- DropIndex
DROP INDEX "inventory"."ix_reservation_scope";

-- DropIndex
DROP INDEX "inventory"."ix_stock_balance_bin_id";

-- DropIndex
DROP INDEX "inventory"."ix_stock_balance_lot_id";

-- DropIndex
DROP INDEX "inventory"."ix_stock_balance_scope";

-- DropIndex
DROP INDEX "inventory"."ix_stock_balance_warehouse_id";

-- DropIndex
DROP INDEX "inventory"."ix_stock_movement_balance_id";

-- DropIndex
DROP INDEX "inventory"."ix_stock_movement_scope";

-- DropIndex
DROP INDEX "inventory"."ix_stock_transfer_from_warehouse_id";

-- DropIndex
DROP INDEX "inventory"."ix_stock_transfer_scope";

-- DropIndex
DROP INDEX "inventory"."ix_stock_transfer_to_warehouse_id";

-- DropIndex
DROP INDEX "inventory"."ix_stocktake_scope";

-- DropIndex
DROP INDEX "inventory"."ix_stocktake_warehouse_id";

-- DropIndex
DROP INDEX "inventory"."ix_stocktake_line_balance_id";

-- DropIndex
DROP INDEX "inventory"."ix_stocktake_line_scope";

-- DropIndex
DROP INDEX "inventory"."ix_stocktake_line_stocktake_id";

-- DropIndex
DROP INDEX "inventory"."ix_transfer_line_lot_id";

-- DropIndex
DROP INDEX "inventory"."ix_transfer_line_scope";

-- DropIndex
DROP INDEX "inventory"."ix_transfer_line_transfer_id";

-- DropIndex
DROP INDEX "inventory"."ix_warehouse_address_id";

-- DropIndex
DROP INDEX "inventory"."ix_warehouse_branch_id";

-- DropIndex
DROP INDEX "inventory"."ix_warehouse_owner_id";

-- DropIndex
DROP INDEX "inventory"."ix_warehouse_scope";

-- DropIndex
DROP INDEX "logistics"."ix_address_district_id";

-- DropIndex
DROP INDEX "logistics"."ix_address_governorate_id";

-- DropIndex
DROP INDEX "logistics"."ix_address_point";

-- DropIndex
DROP INDEX "logistics"."ix_address_scope";

-- DropIndex
DROP INDEX "logistics"."district_governorate_id_id_key";

-- DropIndex
DROP INDEX "logistics"."ix_district_governorate_id";

-- DropIndex
DROP INDEX "logistics"."ix_field_visit_assignment_id";

-- DropIndex
DROP INDEX "logistics"."ix_field_visit_party_id";

-- DropIndex
DROP INDEX "logistics"."ix_field_visit_scope";

-- DropIndex
DROP INDEX "logistics"."ix_route_plan_driver_id";

-- DropIndex
DROP INDEX "logistics"."ix_route_plan_scope";

-- DropIndex
DROP INDEX "logistics"."ix_route_plan_territory_id";

-- DropIndex
DROP INDEX "logistics"."ix_route_plan_vehicle_id";

-- DropIndex
DROP INDEX "logistics"."ix_route_stop_address_id";

-- DropIndex
DROP INDEX "logistics"."ix_route_stop_route_id";

-- DropIndex
DROP INDEX "logistics"."ix_route_stop_scope";

-- DropIndex
DROP INDEX "logistics"."ix_route_stop_shipment_id";

-- DropIndex
DROP INDEX "logistics"."ix_shipping_tariff_origin_zone_id";

-- DropIndex
DROP INDEX "logistics"."ix_shipping_tariff_scope";

-- DropIndex
DROP INDEX "logistics"."ix_shipping_tariff_zone_id";

-- DropIndex
DROP INDEX "logistics"."ix_temperature_reading_scope";

-- DropIndex
DROP INDEX "logistics"."ix_temperature_reading_shipment_id";

-- DropIndex
DROP INDEX "logistics"."ix_vehicle_scope";

-- DropIndex
DROP INDEX "logistics"."ix_zone_boundary";

-- DropIndex
DROP INDEX "logistics"."ix_zone_governorate_id";

-- DropIndex
DROP INDEX "logistics"."ix_zone_scope";

-- DropIndex
DROP INDEX "notifications"."ix_consent_membership_id";

-- DropIndex
DROP INDEX "notifications"."ix_consent_scope";

-- DropIndex
DROP INDEX "notifications"."ix_delivery_attempt_message_id";

-- DropIndex
DROP INDEX "notifications"."ix_delivery_attempt_scope";

-- DropIndex
DROP INDEX "notifications"."ix_message_membership_id";

-- DropIndex
DROP INDEX "notifications"."ix_message_scope";

-- DropIndex
DROP INDEX "notifications"."ix_message_template_id";

-- DropIndex
DROP INDEX "notifications"."ix_template_scope";

-- DropIndex
DROP INDEX "organizations"."ix_branch_address_id";

-- DropIndex
DROP INDEX "organizations"."ix_branch_party_id";

-- DropIndex
DROP INDEX "organizations"."ix_branch_scope";

-- DropIndex
DROP INDEX "organizations"."ix_field_assignment_membership_id";

-- DropIndex
DROP INDEX "organizations"."ix_field_assignment_scope";

-- DropIndex
DROP INDEX "organizations"."ix_field_assignment_territory_id";

-- DropIndex
DROP INDEX "organizations"."ix_membership_principal_id";

-- DropIndex
DROP INDEX "organizations"."ix_membership_scope";

-- DropIndex
DROP INDEX "organizations"."ix_party_scope";

-- DropIndex
DROP INDEX "organizations"."ix_party_member_membership_id";

-- DropIndex
DROP INDEX "organizations"."ix_party_member_party_id";

-- DropIndex
DROP INDEX "organizations"."ix_party_member_scope";

-- DropIndex
DROP INDEX "organizations"."ix_retailer_profile_address_id";

-- DropIndex
DROP INDEX "organizations"."ix_retailer_profile_party_id";

-- DropIndex
DROP INDEX "organizations"."ix_retailer_profile_scope";

-- DropIndex
DROP INDEX "organizations"."ix_scope_parent_id";

-- DropIndex
DROP INDEX "organizations"."ix_supplier_profile_party_id";

-- DropIndex
DROP INDEX "organizations"."ix_supplier_profile_scope";

-- DropIndex
DROP INDEX "organizations"."ix_territory_scope";

-- DropIndex
DROP INDEX "organizations"."ix_territory_zone_id";

-- DropIndex
DROP INDEX "payments"."ix_merchant_account_provider_id";

-- DropIndex
DROP INDEX "payments"."ix_merchant_account_scope";

-- DropIndex
DROP INDEX "payments"."ix_merchant_account_seller_id";

-- DropIndex
DROP INDEX "payments"."ix_payment_allocation_invoice_id";

-- DropIndex
DROP INDEX "payments"."ix_payment_allocation_scope";

-- DropIndex
DROP INDEX "payments"."ix_payment_allocation_transaction_id";

-- DropIndex
DROP INDEX "payments"."ix_payment_intent_merchant_id";

-- DropIndex
DROP INDEX "payments"."ix_payment_intent_order_id";

-- DropIndex
DROP INDEX "payments"."ix_payment_intent_scope";

-- DropIndex
DROP INDEX "payments"."ix_payment_transaction_intent_id";

-- DropIndex
DROP INDEX "payments"."ix_payment_transaction_merchant_id";

-- DropIndex
DROP INDEX "payments"."ix_payment_transaction_scope";

-- DropIndex
DROP INDEX "payments"."ix_payout_merchant_id";

-- DropIndex
DROP INDEX "payments"."ix_payout_scope";

-- DropIndex
DROP INDEX "payments"."ix_provider_settlement_merchant_id";

-- DropIndex
DROP INDEX "payments"."ix_provider_settlement_scope";

-- DropIndex
DROP INDEX "payments"."ix_refund_scope";

-- DropIndex
DROP INDEX "payments"."ix_refund_transaction_id";

-- DropIndex
DROP INDEX "payments"."ix_webhook_inbox_merchant_id";

-- DropIndex
DROP INDEX "payments"."ix_webhook_inbox_scope";

-- DropIndex
DROP INDEX "pricing"."ix_offer_product_id";

-- DropIndex
DROP INDEX "pricing"."ix_offer_scope";

-- DropIndex
DROP INDEX "pricing"."ix_offer_seller_id";

-- DropIndex
DROP INDEX "pricing"."ix_offer_uom_id";

-- DropIndex
DROP INDEX "pricing"."ix_price_rule_offer_id";

-- DropIndex
DROP INDEX "pricing"."ix_price_rule_scope";

-- DropIndex
DROP INDEX "pricing"."ix_promotion_scope";

-- DropIndex
DROP INDEX "pricing"."ix_promotion_seller_id";

-- DropIndex
DROP INDEX "pricing"."ix_tax_rule_category_id";

-- DropIndex
DROP INDEX "pricing"."ix_tax_rule_scope";

-- DropIndex
DROP INDEX "procurement"."ix_goods_receipt_purchase_order_id";

-- DropIndex
DROP INDEX "procurement"."ix_goods_receipt_scope";

-- DropIndex
DROP INDEX "procurement"."ix_goods_receipt_warehouse_id";

-- DropIndex
DROP INDEX "procurement"."ix_landed_cost_receipt_id";

-- DropIndex
DROP INDEX "procurement"."ix_landed_cost_scope";

-- DropIndex
DROP INDEX "procurement"."ix_purchase_line_product_id";

-- DropIndex
DROP INDEX "procurement"."ix_purchase_line_purchase_order_id";

-- DropIndex
DROP INDEX "procurement"."ix_purchase_line_scope";

-- DropIndex
DROP INDEX "procurement"."ix_purchase_line_uom_id";

-- DropIndex
DROP INDEX "procurement"."ix_purchase_order_buyer_id";

-- DropIndex
DROP INDEX "procurement"."ix_purchase_order_scope";

-- DropIndex
DROP INDEX "procurement"."ix_purchase_order_supplier_id";

-- DropIndex
DROP INDEX "procurement"."ix_receipt_line_lot_id";

-- DropIndex
DROP INDEX "procurement"."ix_receipt_line_purchase_line_id";

-- DropIndex
DROP INDEX "procurement"."ix_receipt_line_receipt_id";

-- DropIndex
DROP INDEX "procurement"."ix_receipt_line_scope";

-- DropIndex
DROP INDEX "procurement"."ix_supplier_bill_purchase_order_id";

-- DropIndex
DROP INDEX "procurement"."ix_supplier_bill_scope";

-- DropIndex
DROP INDEX "procurement"."ix_supplier_bill_supplier_id";

-- DropIndex
DROP INDEX "returns"."ix_return_case_order_id";

-- DropIndex
DROP INDEX "returns"."ix_return_case_scope";

-- DropIndex
DROP INDEX "returns"."ix_return_line_case_id";

-- DropIndex
DROP INDEX "returns"."ix_return_line_scope";

-- DropIndex
DROP INDEX "returns"."ix_return_line_shipment_line_id";

-- DropIndex
DROP INDEX "treasury"."ix_cash_handover_cash_session_id";

-- DropIndex
DROP INDEX "treasury"."ix_cash_handover_received_by";

-- DropIndex
DROP INDEX "treasury"."ix_cash_handover_scope";

-- DropIndex
DROP INDEX "treasury"."ix_cash_session_collector_id";

-- DropIndex
DROP INDEX "treasury"."ix_cash_session_scope";

-- DropIndex
DROP INDEX "treasury"."ix_cod_receipt_cash_session_id";

-- DropIndex
DROP INDEX "treasury"."ix_cod_receipt_invoice_id";

-- DropIndex
DROP INDEX "treasury"."ix_cod_receipt_scope";

-- DropIndex
DROP INDEX "treasury"."ix_cod_receipt_shipment_id";

-- DropIndex
DROP INDEX "treasury"."ix_fx_rate_scope";
