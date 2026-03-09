-- ============================================================================
-- Step 4: Extract Images to Stage
-- ============================================================================
-- Creates a stored procedure that reads the base64-encoded images from 
-- PARSED_DOCS and saves them as files on EXTRACTED_IMAGES_STAGE.
-- Also creates the IMAGE_METADATA table with figure labels extracted
-- from the parsed markdown text.
-- ============================================================================

USE DATABASE PRODUCT_DATA_AGENT;
USE SCHEMA DATA;

-- Stored procedure: decodes base64 images and uploads to stage
CREATE OR REPLACE PROCEDURE SAVE_PARSED_IMAGES_TO_STAGE()
RETURNS VARCHAR
LANGUAGE PYTHON
RUNTIME_VERSION = '3.9'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'run'
AS
$$
import base64
import os
import tempfile
import re

def run(session):
    results = session.sql("""
        SELECT 
            source_file,
            f.index as img_index,
            f.value:id::STRING as img_id,
            f.value:image_base64::STRING as image_base64
        FROM PRODUCT_DATA_AGENT.DATA.PARSED_DOCS,
             LATERAL FLATTEN(input => parsed:images) f
        WHERE ARRAY_SIZE(parsed:images) > 0
    """).collect()
    
    uploaded = 0
    with tempfile.TemporaryDirectory() as temp_dir:
        for row in results:
            source_file = row['SOURCE_FILE']
            img_id = row['IMG_ID']
            image_base64 = row['IMAGE_BASE64']
            
            base_name = re.sub(r'\.(pdf|docx)$', '', source_file, flags=re.IGNORECASE)
            filename = f"{base_name}_{img_id}"
            
            if ';base64,' in image_base64:
                base64_data = image_base64.split(';base64,')[1]
            else:
                base64_data = image_base64
            
            image_bytes = base64.b64decode(base64_data)
            
            temp_path = os.path.join(temp_dir, filename)
            with open(temp_path, 'wb') as f:
                f.write(image_bytes)
            
            session.file.put(
                temp_path,
                '@PRODUCT_DATA_AGENT.DATA.EXTRACTED_IMAGES_STAGE',
                auto_compress=False,
                overwrite=True
            )
            uploaded += 1
            os.remove(temp_path)
    
    return f"Uploaded {uploaded} images"
$$;

-- Run the extraction
CALL SAVE_PARSED_IMAGES_TO_STAGE();

-- Refresh stage directory
ALTER STAGE EXTRACTED_IMAGES_STAGE REFRESH;

-- Create IMAGE_METADATA by extracting figure captions from the parsed markdown
-- The pattern looks for text immediately following ![img-X.jpeg](img-X.jpeg) references
CREATE OR REPLACE TABLE IMAGE_METADATA AS
SELECT 
    p.source_file,
    f.index as img_index,
    f.value:id::STRING as img_id,
    CONCAT(
        REPLACE(REPLACE(p.source_file, '.pdf', ''), '.docx', ''),
        '_',
        f.value:id::STRING
    ) as image_filename,
    COALESCE(
        REGEXP_SUBSTR(
            p.parsed:content::STRING, 
            CONCAT(f.value:id::STRING, '\\)\\n([^\\n]+)'),
            1, 1, 'e'
        ),
        'Unknown'
    ) as image_label
FROM PARSED_DOCS p,
     LATERAL FLATTEN(input => p.parsed:images) f;

-- Verify
SELECT image_filename, image_label 
FROM IMAGE_METADATA 
WHERE image_label != 'Unknown'
ORDER BY source_file, img_index;
