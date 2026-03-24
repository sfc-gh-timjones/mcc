-- ============================================================================
-- Step 3: Parse Documents
-- ============================================================================
-- Uses AI_PARSE_DOCUMENT to extract text and images from each PDF/DOCX.
-- The 'extract_images': true option pulls out embedded images as base64.
-- This step may take a few minutes depending on document count/size.
-- ============================================================================

USE DATABASE PRODUCT_AGENT;
USE SCHEMA DATA;

CREATE OR REPLACE TABLE PARSED_DOCS AS
SELECT 
    RELATIVE_PATH as source_file,
    AI_PARSE_DOCUMENT(
        TO_FILE('@DOCS_STAGE', RELATIVE_PATH),
        {'mode': 'LAYOUT', 'extract_images': true}
    ) as parsed
FROM DIRECTORY('@DOCS_STAGE')
WHERE RELATIVE_PATH LIKE '%.pdf' OR RELATIVE_PATH LIKE '%.docx';

-- Verify
SELECT source_file, LENGTH(parsed:content::VARCHAR) as content_length, ARRAY_SIZE(parsed:images) as image_count
FROM PARSED_DOCS
ORDER BY source_file;
