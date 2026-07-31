-- Create the dedicated test database on fresh Postgres initialization.
-- The test suite runs real Alembic migrations against this database so it
-- is fully separate from the dev database (foodlink_inventory).
CREATE DATABASE foodlink_inventory_test;
