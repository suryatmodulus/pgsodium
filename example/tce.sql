CREATE SCHEMA IF NOT EXISTS pgsodium;
CREATE EXTENSION IF NOT EXISTS pgsodium WITH SCHEMA pgsodium CASCADE;

CREATE TABLE test (
  secret text,
  associated text,
  nonce bytea,
  secret2 text,
  associated2 text,
  secret2_key_id uuid,
  nonce2 bytea
);

CREATE ROLE bob with login password 'foo';

SECURITY LABEL FOR pgsodium ON ROLE bob is 'ACCESS public.test';

SELECT format('ENCRYPT WITH KEY ID %s ASSOCIATED associated NONCE nonce',
              (pgsodium.create_key('aead-det', 'Optional Comment for Secret Key')).id) AS seclabel \gset

SELECT id AS secret2_key_id FROM pgsodium.create_key('aead-det', 'Comment for Secret2 Key') \gset

SECURITY LABEL FOR pgsodium	ON COLUMN test.secret IS :'seclabel';

SECURITY LABEL FOR pgsodium	ON COLUMN test.secret2 IS
                 'ENCRYPT WITH KEY COLUMN secret2_key_id ASSOCIATED associated2 NONCE nonce2';

SELECT pgsodium.crypto_aead_det_noncegen() aead_nonce \gset
SELECT pgsodium.crypto_aead_det_noncegen() aead_nonce2 \gset

INSERT INTO public.test (secret, associated, nonce, secret2, associated2, nonce2, secret2_key_id)
    VALUES ('sssh', 'bob was here', :'aead_nonce', 'aaahh', 'alice association', :'aead_nonce2', :'secret2_key_id'::uuid);
