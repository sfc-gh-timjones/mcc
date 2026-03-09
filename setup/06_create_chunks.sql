-- ============================================================================
-- Step 6: Create Document Chunks
-- ============================================================================
-- Combines two types of searchable content into DOC_CHUNKS:
--   1. Text chunks: Full parsed text from each document
--   2. Curve chunks: AI-generated graph analysis from Step 5
--
-- Both are indexed by Cortex Search so the agent can answer
-- questions about both text specs and curve/graph data.
-- ============================================================================

USE DATABASE PRODUCT_DATA_AGENT;
USE SCHEMA DATA;

CREATE OR REPLACE TABLE DOC_CHUNKS AS
WITH text_chunks AS (
    SELECT 
        CONCAT(source_file, '_text') as chunk_key,
        source_file,
        REPLACE(REPLACE(source_file, '.pdf', ''), '.docx', '') as document_name,
        CASE 
            WHEN POSITION('(' IN source_file) > 0 
            THEN TRIM(SUBSTRING(source_file, 1, POSITION('(' IN source_file) - 1))
            ELSE REPLACE(REPLACE(source_file, '.pdf', ''), '.docx', '')
        END as product_name,
        CASE 
            WHEN source_file ILIKE '%reliability%' THEN 'Reliability Report'
            WHEN source_file ILIKE '%package%' THEN 'Package Specification'
            WHEN source_file ILIKE '%environmental%' THEN 'Environmental Statement'
            WHEN source_file ILIKE '%soldering%' THEN 'Soldering Guide'
            WHEN source_file ILIKE '%halogen%' THEN 'Halogen Free Package List'
            WHEN source_file ILIKE '%MCDS%' THEN 'Material Content Data Sheet'
            ELSE 'Product Datasheet'
        END as document_type,
        1 as chunk_id,
        parsed:content::VARCHAR as chunk_text,
        CURRENT_TIMESTAMP() as created_at
    FROM PARSED_DOCS
    WHERE LENGTH(parsed:content::VARCHAR) > 0
),
curve_chunks AS (
    SELECT 
        CONCAT(source_file, '_curve_', img_id) as chunk_key,
        source_file,
        REPLACE(REPLACE(source_file, '.pdf', ''), '.docx', '') as document_name,
        CASE 
            WHEN POSITION('(' IN source_file) > 0 
            THEN TRIM(SUBSTRING(source_file, 1, POSITION('(' IN source_file) - 1))
            ELSE REPLACE(REPLACE(source_file, '.pdf', ''), '.docx', '')
        END as product_name,
        'Curve Data' as document_type,
        100 + ROW_NUMBER() OVER (PARTITION BY source_file ORDER BY img_id) as chunk_id,
        CONCAT('Graph: ', image_label, '\n\n', curve_readings) as chunk_text,
        CURRENT_TIMESTAMP() as created_at
    FROM CURVE_DATA
)
SELECT * FROM text_chunks
UNION ALL
SELECT * FROM curve_chunks;

-- Verify
SELECT 
    CASE WHEN chunk_key LIKE '%_curve_%' THEN 'Curve Analysis' ELSE 'Document Text' END as chunk_type,
    COUNT(*) as count
FROM DOC_CHUNKS
GROUP BY 1;
