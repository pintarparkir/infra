-- Bootstrap script: creates one database per microservice.
-- Each service then runs its own migrations against its own DB.
--
-- This file is mounted at /docker-entrypoint-initdb.d/ and runs once on first
-- container start. After that, schema lives inside the named volume `pg_data`.

CREATE DATABASE user_service;
CREATE DATABASE reservation_service;
CREATE DATABASE billing_service;
CREATE DATABASE payment_service;

-- pgcrypto must be enabled inside each DB that uses it; the per-service
-- migrations handle that via `CREATE EXTENSION IF NOT EXISTS pgcrypto`.
