BEGIN;

-- Keep the persisted OTP delivery channel consistent with the provider that
-- actually accepted delivery. The browser cannot call this function directly.
CREATE FUNCTION app_private.set_otp_delivery_channel(cid uuid, ch text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path=pg_catalog,pg_temp
AS $$
BEGIN
 IF ch NOT IN ('WHATSAPP','SMS') THEN
  RETURN false;
 END IF;

 UPDATE identity.otp_challenge
 SET channel=ch, updated_at=clock_timestamp()
 WHERE id=cid
   AND channel='WHATSAPP'
   AND consumed_at IS NULL
   AND archived_at IS NULL
   AND expires_at>clock_timestamp();

 RETURN FOUND;
END
$$;

REVOKE ALL ON FUNCTION app_private.set_otp_delivery_channel(uuid,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION app_private.set_otp_delivery_channel(uuid,text) TO wholesale_runtime;

COMMIT;
