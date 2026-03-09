-- ============================================================================
-- Step 1: Create Infrastructure
-- ============================================================================
-- Creates the database, schemas, and stages needed for the pipeline.
-- Run this first.
-- ============================================================================

CREATE DATABASE IF NOT EXISTS PRODUCT_DATA_AGENT;

CREATE SCHEMA IF NOT EXISTS PRODUCT_DATA_AGENT.DATA;
CREATE SCHEMA IF NOT EXISTS PRODUCT_DATA_AGENT.AGENTS;

CREATE OR REPLACE STAGE PRODUCT_DATA_AGENT.DATA.DOCS_STAGE
    DIRECTORY = (ENABLE = TRUE)
    ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');

CREATE OR REPLACE STAGE PRODUCT_DATA_AGENT.DATA.EXTRACTED_IMAGES_STAGE
    DIRECTORY = (ENABLE = TRUE)
    ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');
