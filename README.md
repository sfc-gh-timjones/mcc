# MCC Product Chatbot

A Snowflake Cortex Agent-powered chatbot for querying MCC (Micro Commercial Components) semiconductor product documentation. Uses AI-extracted curve data from datasheet graphs to answer technical questions about specifications, electrical characteristics, and performance curves.

## Architecture

```
PDF/DOCX Files
     │
     ▼
AI_PARSE_DOCUMENT (text + image extraction)
     │
     ├──▶ Text Content ──▶ DOC_CHUNKS ──▶ Cortex Search ──▶ Cortex Agent
     │
     └──▶ Extracted Images ──▶ AI_COMPLETE (vision) ──▶ Curve Readings ──▶ DOC_CHUNKS
```

## What It Does

1. **Parses PDFs** using `AI_PARSE_DOCUMENT` with image extraction enabled
2. **Extracts graph images** from the parsed output and saves them to a stage
3. **Analyzes each graph** using `AI_COMPLETE` with a vision model to read axis labels, data points, and curve characteristics
4. **Indexes everything** in Cortex Search -- both the document text and the AI-generated curve analysis
5. **Cortex Agent** answers natural language questions using the indexed data

This means the agent can answer questions like *"at what temperature does the forward current start to derate?"* using data points that were read from the actual graph image by the vision model.

## Prerequisites

- Snowflake account with Cortex features enabled
- ACCOUNTADMIN or role with CREATE DATABASE privilege
- A warehouse (scripts use `WH_XS` -- update if needed)

## Setup Guide

Run the scripts in `setup/` in order. Each script is self-contained and can be run in Snowsight or SnowSQL.

### Step 1: Create Infrastructure
```sql
-- Creates database, schemas, and stages
@setup/01_create_infrastructure.sql
```

Creates:
- `PRODUCT_DATA_AGENT` database
- `DATA` schema (tables, stages, search service)
- `AGENTS` schema (agent)
- `DOCS_STAGE` (source documents)
- `EXTRACTED_IMAGES_STAGE` (curve images)

### Step 2: Upload Documents
```sql
-- Update the file path in the script to match your local clone
@setup/02_upload_documents.sql
```

Uploads all PDFs and DOCX files from `data/` to `DOCS_STAGE` and creates the `RAW_DOCS` catalog table.

### Step 3: Parse Documents
```sql
@setup/03_parse_documents.sql
```

Runs `AI_PARSE_DOCUMENT` on every file with `{'mode': 'LAYOUT', 'extract_images': true}`. This extracts:
- Full document text as markdown
- All embedded images as base64 with IDs (`img-0.jpeg`, `img-1.jpeg`, etc.)
- Image references inline with figure captions in the text

### Step 4: Extract Images to Stage
```sql
@setup/04_extract_images.sql
```

Creates and runs a Python stored procedure that:
1. Reads base64-encoded images from `PARSED_DOCS`
2. Decodes them and saves as files to `EXTRACTED_IMAGES_STAGE`
3. Names them as `ProductName(Package)_img-X.jpeg`

Also creates `IMAGE_METADATA` by extracting figure captions from the parsed markdown (e.g., `![img-2.jpeg](img-2.jpeg)\nFig. 1 - Forward Current Derating Curve`).

### Step 5: Analyze Curves with Vision Model
```sql
@setup/05_analyze_curves.sql
```

This is the key step. For each graph image with a figure label, it calls:

```sql
AI_COMPLETE('claude-3-5-sonnet', <prompt>, TO_FILE(@STAGE, filename))
```

The vision model reads the graph and outputs structured data:
```
Graph: Fig. 1 - Forward Current Derating Curve
- X-axis: Case Temperature (°C)
- Y-axis: Average Forward Current (A)
- At 25°C, Forward Current = 40A
- At 100°C, Forward Current = 40A
- At 125°C, Forward Current = 25A
- Linear derating begins at 100°C
```

Results are stored in the `CURVE_DATA` table. This step takes several minutes.

### Step 6: Create Searchable Chunks
```sql
@setup/06_create_chunks.sql
```

Combines two types of content into `DOC_CHUNKS`:

| Chunk Type | Source | Example |
|------------|--------|---------|
| **Text** | Full parsed document text | Specs tables, pin descriptions, ordering info |
| **Curve** | AI-generated graph analysis | "At 100°C, Forward Current = 40A" |

Both types get indexed by Cortex Search.

### Step 7: Create Search Service and Agent
```sql
@setup/07_create_search_and_agent.sql
```

Creates:
- **Cortex Search Service** on `DOC_CHUNKS.chunk_text` with product/document attributes
- **Cortex Agent** using claude-4-sonnet with instructions to use `~` for graph-derived values

Test the agent in Snowsight under AI & ML > Snowflake Intelligence.

## Project Structure

```
mcc_pdf_chatbot/
├── data/                          # Source documents
│   ├── MBRB4040CTQ(D2-PAK).pdf   # Product datasheets
│   ├── 2N7002(SOT-23).pdf
│   ├── SICW025N120Y(TO-247AB).pdf
│   ├── SMB10J5.0AHE3_SMB10J85CAHE3(SMB).pdf
│   ├── Halogen_Free_Package_List.docx
│   ├── MCC Environmental Statement.pdf
│   ├── soldering profile.pdf
│   ├── *_Package*.pdf             # Package drawings
│   ├── *ReliabilityReport*.pdf    # Reliability data
│   └── MCDS_*.pdf                 # Material content data sheets
├── setup/
│   ├── 01_create_infrastructure.sql
│   ├── 02_upload_documents.sql
│   ├── 03_parse_documents.sql
│   ├── 04_extract_images.sql
│   ├── 05_analyze_curves.sql
│   ├── 06_create_chunks.sql
│   └── 07_create_search_and_agent.sql
└── README.md
```

## Snowflake Objects

| Object | Type | Description |
|--------|------|-------------|
| `PRODUCT_DATA_AGENT` | Database | Main database |
| `DATA` | Schema | Data tables and stages |
| `AGENTS` | Schema | Agent |
| `DOCS_STAGE` | Stage | Source PDF/DOCX files |
| `EXTRACTED_IMAGES_STAGE` | Stage | Graph/curve images |
| `RAW_DOCS` | Table | File catalog from stage directory |
| `PARSED_DOCS` | Table | AI_PARSE_DOCUMENT output (text + images) |
| `IMAGE_METADATA` | Table | Image filenames and figure labels |
| `CURVE_DATA` | Table | AI_COMPLETE vision analysis of each graph |
| `DOC_CHUNKS` | Table | Searchable chunks (text + curve readings) |
| `MCC_PRODUCT_SEARCH` | Cortex Search | Vector search over DOC_CHUNKS |
| `MCC_PRODUCT_CHATBOT` | Agent | Cortex Agent |

## Troubleshooting

**Agent not responding**: Check warehouse is running and search service is ACTIVE (`SHOW CORTEX SEARCH SERVICES IN SCHEMA DATA`)

**Search returns no results**: Verify chunks exist (`SELECT COUNT(*) FROM DOC_CHUNKS`) and wait for indexing to complete

**Curve data missing**: Step 5 only processes images with figure labels. Check `IMAGE_METADATA` for labels (`SELECT * FROM IMAGE_METADATA WHERE image_label != 'Unknown'`)

## License

MIT
