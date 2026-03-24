-- ============================================================================
-- Step 5: Analyze Curves with AI_COMPLETE (Vision)
-- ============================================================================
-- Sends each graph/curve image to a vision-capable LLM to extract:
--   - Axis labels and units
--   - Key data points read from the curve
--   - Temperature conditions and other parameters
--
-- Only processes images with figure labels (Fig., Curve, etc.)
-- This step may take several minutes due to per-image LLM calls.
-- ============================================================================

USE DATABASE PRODUCT_AGENT;
USE SCHEMA DATA;

CREATE OR REPLACE TABLE CURVE_DATA AS
SELECT 
    m.source_file,
    m.img_id,
    m.image_filename,
    m.image_label,
    AI_COMPLETE(
        'claude-3-5-sonnet',
        CONCAT(
            'Analyze this graph titled "', m.image_label, 
            '". Extract key data points from the curve(s). ',
            'Format each reading as: "At [X-value with unit], [Y-parameter] = [Y-value with unit]". ',
            'Include axis labels and any temperature conditions noted.'
        ),
        TO_FILE('@EXTRACTED_IMAGES_STAGE', m.image_filename)
    ) as curve_readings
FROM IMAGE_METADATA m
WHERE m.image_label ILIKE '%Fig%' 
   OR m.image_label ILIKE '%Curve%'
   OR m.image_label ILIKE '%Characteristic%';

-- Verify
SELECT source_file, image_label, LEFT(curve_readings::VARCHAR, 150) as readings_preview
FROM CURVE_DATA
ORDER BY source_file, img_id;
