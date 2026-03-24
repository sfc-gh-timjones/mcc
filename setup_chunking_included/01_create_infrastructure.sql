-- ============================================================================
-- Step 1: Create Infrastructure
-- ============================================================================
-- Creates the PRODUCT_AGENT database, schemas, and stages.
-- Uses the shared TEST_WAREHOUSE (does not recreate it).
-- This is 100% independent from the PRODUCT_DATA_AGENT project.
-- ============================================================================

CREATE WAREHOUSE IF NOT EXISTS TEST_WAREHOUSE
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 30
    AUTO_RESUME = TRUE;

CREATE DATABASE IF NOT EXISTS PRODUCT_AGENT;

CREATE SCHEMA IF NOT EXISTS PRODUCT_AGENT.DATA;
CREATE SCHEMA IF NOT EXISTS PRODUCT_AGENT.AGENTS;

CREATE OR REPLACE STAGE PRODUCT_AGENT.DATA.DOCS_STAGE
    DIRECTORY = (ENABLE = TRUE)
    ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');

CREATE OR REPLACE STAGE PRODUCT_AGENT.DATA.EXTRACTED_IMAGES_STAGE
    DIRECTORY = (ENABLE = TRUE)
    ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');

CREATE OR REPLACE STAGE PRODUCT_AGENT.DATA.CSV_STAGE;
