-- ============================================================================
-- Step 2: Upload Documents
-- ============================================================================
-- Refreshes the stage directory and creates the RAW_DOCS catalog table.
-- Upload files to DOCS_STAGE before running this script (see README).
-- ============================================================================

-- Refresh directory metadata
ALTER STAGE PRODUCT_DATA_AGENT.DATA.DOCS_STAGE REFRESH;

-- Create RAW_DOCS catalog from stage directory
CREATE OR REPLACE TABLE PRODUCT_DATA_AGENT.DATA.RAW_DOCS AS
SELECT 
    RELATIVE_PATH as file_path,
    FILE_URL as file_url,
    SIZE as file_size,
    LAST_MODIFIED as last_modified,
    BUILD_SCOPED_FILE_URL(@PRODUCT_DATA_AGENT.DATA.DOCS_STAGE, RELATIVE_PATH) as scoped_file_url
FROM DIRECTORY(@PRODUCT_DATA_AGENT.DATA.DOCS_STAGE);

-- Verify
SELECT file_path, file_size FROM PRODUCT_DATA_AGENT.DATA.RAW_DOCS ORDER BY file_path;
