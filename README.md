# MCC Product Chatbot - Deployment Guide

Deploy a Cortex Agent for MCC semiconductor product documentation with AI-extracted curve data and a 43,000+ row product catalog.

## What's Included

- **Document Pipeline**: AI_PARSE_DOCUMENT + AI_COMPLETE (vision) to extract text and read data points from graph images
- **Cortex Search Service**: Vector search over document text and curve readings
- **Product Catalog**: 43,000+ part numbers with electrical specs, package types, lifecycle status
- **Semantic View**: MCC_PRODUCT_CATALOG with verified queries for text-to-SQL
- **Cortex Agent**: MCC_PRODUCT_CHATBOT with search + analyst tools

## Architecture

```
PDF/DOCX Files ──▶ AI_PARSE_DOCUMENT ──▶ Text + Images
                                              │
                       ┌──────────────────────┤
                       ▼                      ▼
               Extracted Images         Text Chunks
                       │                      │
                       ▼                      │
              AI_COMPLETE (vision)            │
               Curve Analysis                 │
                       │                      │
                       ▼                      ▼
                    DOC_CHUNKS (text + curve readings)
                           │
                           ▼
                    Cortex Search Service ────────────┐
                                                     │
CSV Catalog ──▶ PRODUCT_CATALOG ──▶ Semantic View    │
                                         │           │
                                         ▼           │
                              Cortex Analyst         │
                              (text-to-SQL)          │
                                         │           │
                                         ▼           ▼
                                    Cortex Agent (2 tools)
                                         │
                                         ▼
                               Snowflake Intelligence
```

## Prerequisites

- Snowflake account with Cortex features enabled
- ACCOUNTADMIN or role with CREATE DATABASE privilege
- A warehouse named `WH_XS` (or update the scripts to use your warehouse)
- [SnowSQL](https://docs.snowflake.com/en/user-guide/snowsql) or [Snowflake CLI](https://docs.snowflake.com/en/developer-guide/snowflake-cli/installation/installation) for file uploads (Steps 2 and 8 use `PUT` which is not supported in Snowsight worksheets)

## Deployment Steps

### Optional: Import Project from Git

If you'd like to import the project directly into Snowsight Workspaces instead of copying SQL into worksheets:

1. Create the API integration for GitHub (one-time setup, requires ACCOUNTADMIN):

```sql
CREATE OR REPLACE API INTEGRATION GIT_INTEGRATION
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/')
  ENABLED = TRUE;
```

2. Navigate to **Projects > Workspaces**
3. Click on the workspace name dropdown at the top, then select **Create from Git Repository**
4. Enter repository URL: `https://github.com/sfc-gh-timjones/mcc`
5. Select `GIT_INTEGRATION` as the API integration
6. Click **Create**

### Step 1: Create Infrastructure

Open `setup/01_create_infrastructure.sql` in a Snowsight worksheet and run it.

Creates database, schemas, and stages for documents and images.

### Step 2: Upload Documents

> **Requires SnowSQL or Snowflake CLI** (PUT is not supported in Snowsight worksheets).

Update the file paths in `setup/02_upload_documents.sql` to match your local file locations, then run:

```sql
PUT 'file:///path/to/data/*.pdf' @PRODUCT_DATA_AGENT.DATA.DOCS_STAGE AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
PUT 'file:///path/to/data/*.docx' @PRODUCT_DATA_AGENT.DATA.DOCS_STAGE AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
```

After uploading, open `setup/02_upload_documents.sql` in a Snowsight worksheet and run it to refresh the stage and create the `RAW_DOCS` catalog table.

### Step 3: Parse Documents

Open `setup/03_parse_documents.sql` in a Snowsight worksheet and run it.

Runs `AI_PARSE_DOCUMENT` with image extraction on every file. Takes a few minutes.

### Step 4: Extract Images to Stage

Open `setup/04_extract_images.sql` in a Snowsight worksheet and run it.

Creates a stored procedure that decodes base64 images from parsed output and uploads them to `EXTRACTED_IMAGES_STAGE`. Also creates `IMAGE_METADATA` with figure captions.

### Step 5: Analyze Curves with Vision Model

Open `setup/05_analyze_curves.sql` in a Snowsight worksheet and run it.

Sends each graph image to `AI_COMPLETE` (vision) to read axis labels, data points, and curve characteristics. Takes several minutes.

### Step 6: Create Searchable Chunks

Open `setup/06_create_chunks.sql` in a Snowsight worksheet and run it.

Combines document text and AI-generated curve readings into `DOC_CHUNKS`.

### Step 7: Create Cortex Search Service

Open `setup/07_create_search_and_agent.sql` in a Snowsight worksheet and run it.

Creates a Cortex Search Service over `DOC_CHUNKS`. Wait for indexing to complete before proceeding.

Verify:
```sql
SHOW CORTEX SEARCH SERVICES IN SCHEMA DATA;
```

### Step 8: Ingest Product Catalog, Semantic View, and Agent

> **Requires SnowSQL or Snowflake CLI** for the CSV upload.

Upload the CSV first:
```sql
PUT 'file:///path/to/data/product sample data.csv' @PRODUCT_DATA_AGENT.DATA.CSV_STAGE AUTO_COMPRESS=FALSE;
```

Then open `setup/08_ingest_catalog_and_semantic_view.sql` in a Snowsight worksheet and run it (select all, then run).

This script creates the `PRODUCT_CATALOG` table, deploys the `MCC_PRODUCT_CATALOG` Semantic View, and creates the Cortex Agent with both tools.

Verify:
```sql
SHOW SEMANTIC VIEWS IN PRODUCT_DATA_AGENT.DATA;
DESC SEMANTIC VIEW PRODUCT_DATA_AGENT.DATA.MCC_PRODUCT_CATALOG;
SHOW AGENTS IN SCHEMA AGENTS;
```

## Sample Questions

Go to **AI & ML > Snowflake Intelligence**, make sure `MCC_PRODUCT_CHATBOT` is selected, and start asking questions!

Try these:

- How many active MOSFETs does MCC have?
- What is the forward current derating curve for MBRB4040CTQ?
- What package types are available for Schottky Barrier Rectifiers?
- What are the electrical specs for the 2N7002?
- Show me all active N-Channel MOSFETs in TO-220AB package sorted by drain-source voltage.
- How many automotive qualified parts does MCC have by product family?
- What is the maximum forward current at 125C for MBRB4040CTQ?
- What are the capacitance characteristics of the SICW025N120Y?

## Files Reference

| File | Purpose |
|------|---------|
| `setup/01_create_infrastructure.sql` | Database, schemas, stages |
| `setup/02_upload_documents.sql` | Upload PDF/DOCX files to stage |
| `setup/03_parse_documents.sql` | AI_PARSE_DOCUMENT extraction |
| `setup/04_extract_images.sql` | Decode images to stage + metadata |
| `setup/05_analyze_curves.sql` | AI_COMPLETE vision curve analysis |
| `setup/06_create_chunks.sql` | Combine text + curve chunks |
| `setup/07_create_search_and_agent.sql` | Cortex Search Service |
| `setup/08_ingest_catalog_and_semantic_view.sql` | CSV, Semantic View, Agent |

## Troubleshooting

**Agent not responding**: Check warehouse is running and search service is ACTIVE (`SHOW CORTEX SEARCH SERVICES IN SCHEMA DATA`)

**Search returns no results**: Verify chunks exist (`SELECT COUNT(*) FROM DOC_CHUNKS`) and wait for indexing to complete

**Curve data missing**: Step 5 only processes images with figure labels. Check `IMAGE_METADATA` for labels

**Semantic view errors**: YAML uses `VARCHAR` (not `TEXT`) and `NUMBER` (not `INT`/`FLOAT`). Metrics do not have a `data_type` field.

**CSV load issues**: COPY INTO uses `ON_ERROR = 'CONTINUE'`. Check `SELECT COUNT(*) FROM PRODUCT_CATALOG` returns ~43,007
