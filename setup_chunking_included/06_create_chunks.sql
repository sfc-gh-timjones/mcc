-- ============================================================================
-- Step 6: Create Document Chunks (with SPLIT_TEXT_RECURSIVE_CHARACTER)
-- ============================================================================
-- KEY DIFFERENCE from the original setup:
-- Instead of 1 text chunk per document, this uses
-- SNOWFLAKE.CORTEX.SPLIT_TEXT_RECURSIVE_CHARACTER to split each document
-- into ~512-token chunks with ~200-token overlap.
--
-- Token-to-character conversion (approx 4 chars/token):
--   512 tokens  ≈ 2,048 characters (chunk size)
--   200 tokens  ≈   800 characters (overlap)
--
-- Uses 'markdown' format since AI_PARSE_DOCUMENT returns markdown content.
-- Curve chunks from AI_COMPLETE vision analysis are added as-is.
-- ============================================================================

USE DATABASE PRODUCT_AGENT;
USE SCHEMA DATA;

CREATE OR REPLACE TABLE DOC_CHUNKS AS
WITH text_chunks AS (
    SELECT 
        CONCAT(source_file, '_text_', seq) as chunk_key,
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
        seq as chunk_id,
        c.value::VARCHAR as chunk_text,
        CURRENT_TIMESTAMP() as created_at
    FROM PARSED_DOCS,
         LATERAL FLATTEN(
             input => SNOWFLAKE.CORTEX.SPLIT_TEXT_RECURSIVE_CHARACTER(
                 parsed:content::VARCHAR,
                 'markdown',
                 2048,
                 800
             )
         ) c,
         LATERAL (SELECT ROW_NUMBER() OVER (ORDER BY c.index) as seq) s
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

-- Verify chunk counts
SELECT 
    CASE WHEN chunk_key LIKE '%_curve_%' THEN 'Curve Analysis' ELSE 'Document Text' END as chunk_type,
    COUNT(*) as count,
    AVG(LENGTH(chunk_text)) as avg_chunk_chars,
    MIN(LENGTH(chunk_text)) as min_chunk_chars,
    MAX(LENGTH(chunk_text)) as max_chunk_chars
FROM DOC_CHUNKS
GROUP BY 1;
