BEGIN;
-- Only the trusted API runtime may call this session resolver. It returns no secrets.
CREATE FUNCTION app_private.resolve_session(digest_arg text,audience_arg text)
RETURNS TABLE(tenant_id uuid,membership_id uuid,scope_id uuid,audience text)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog,pg_temp AS $$
 SELECT s.tenant_id,s.membership_id,s.scope_id,s.audience FROM identity.session s
 JOIN organizations.membership m ON m.tenant_id=s.tenant_id AND m.id=s.membership_id
 JOIN identity.principal p ON p.id=m.principal_id
 JOIN organizations.tenant t ON t.id=s.tenant_id
 WHERE digest_arg ~ '^[0-9a-f]{64}$' AND s.token_digest=digest_arg
 AND s.audience=audience_arg AND audience_arg IN ('retailer','supplier','field','driver','command')
 AND s.archived_at IS NULL AND s.revoked_at IS NULL AND s.expires_at>now()
 AND m.archived_at IS NULL AND m.status='ACTIVE' AND p.archived_at IS NULL AND p.status='ACTIVE'
 AND t.archived_at IS NULL AND t.status='ACTIVE'
 AND (s.scope_id IS NULL OR EXISTS(SELECT 1 FROM organizations.scope sc WHERE sc.tenant_id=s.tenant_id AND sc.id=s.scope_id AND sc.archived_at IS NULL))
 AND (s.device_id IS NULL OR EXISTS(SELECT 1 FROM identity.device d WHERE d.tenant_id=s.tenant_id AND d.id=s.device_id AND d.membership_id=s.membership_id AND d.archived_at IS NULL AND d.revoked_at IS NULL))
$$;
REVOKE ALL ON FUNCTION app_private.resolve_session(text,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION app_private.resolve_session(text,text) TO wholesale_runtime;
-- No runtime-readable credential digest, even if a role holds the historical read permission.
REVOKE SELECT ON identity.session,identity.device FROM wholesale_runtime;
COMMIT;
