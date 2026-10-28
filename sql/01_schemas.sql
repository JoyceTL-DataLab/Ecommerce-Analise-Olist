-- 01_schemas.sql
-- Recria os schemas do modelo dimensional.
-- Pré-requisito: schema `staging` já carregado pelo ETL (notebook 01).

DROP SCHEMA IF EXISTS marts CASCADE;
DROP SCHEMA IF EXISTS core  CASCADE;
CREATE SCHEMA core;
CREATE SCHEMA marts;
