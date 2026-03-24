-- ============================================================================
-- Step 7: Create Cortex Search Service
-- ============================================================================
-- Creates the Cortex Search service over DOC_CHUNKS (both text and curve data).
-- The agent is created in Step 10 after the semantic view is deployed.
--
-- ============================================================================

USE DATABASE PRODUCT_DATA_AGENT;

-- Cortex Search: indexes chunk_text with vector embeddings for semantic search
CREATE OR REPLACE CORTEX SEARCH SERVICE DATA.MCC_PRODUCT_SEARCH
    ON chunk_text
    ATTRIBUTES product_name, document_name, document_type
    WAREHOUSE = TEST_WAREHOUSE
    TARGET_LAG = '1 hour'
AS (
    SELECT 
        chunk_key,
        source_file,
        document_name,
        product_name,
        document_type,
        chunk_id,
        chunk_text,
        created_at
    FROM DATA.DOC_CHUNKS
);

-- Verify search service is indexing
SHOW CORTEX SEARCH SERVICES IN SCHEMA DATA;
