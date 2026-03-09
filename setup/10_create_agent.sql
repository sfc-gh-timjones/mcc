-- ============================================================================
-- Step 10: Create Cortex Agent
-- ============================================================================
-- Creates the MCC Product Chatbot agent with two tools:
--   1) Cortex Search for unstructured document search
--   2) Cortex Analyst for structured catalog queries via text-to-SQL
-- ============================================================================

USE DATABASE PRODUCT_DATA_AGENT;

CREATE OR REPLACE AGENT AGENTS.MCC_PRODUCT_CHATBOT
  COMMENT = 'Chatbot for MCC (Micro Commercial Components) product documentation and catalog data'
  PROFILE = '{"display_name": "MCC Product Assistant", "avatar": "📦"}'
  FROM SPECIFICATION $$
  {
    "models": {
      "orchestration": "claude-4-sonnet"
    },
    "instructions": {
      "orchestration": "You are an expert assistant for MCC (Micro Commercial Components) semiconductor products. You have two tools: 1) search_mcc_products for searching unstructured documentation (datasheets, reliability reports, package specs), and 2) query_product_catalog for querying the structured product catalog database with 43,000+ part numbers. Use search for questions about specific datasheet content, graphs, curves, or document text. Use the catalog query tool for questions about part availability, product families, package types, lifecycle status, electrical specifications across the catalog, or counting/filtering parts.",
      "response": "Provide clear, accurate technical information. When quoting specifications from datasheets tables, include the exact values with units. However, when reading values from graphs or curves (such as derating curves, characteristic curves, capacitance vs voltage, etc.), use approximate notation with '~' since graph readings are inherently estimates. If information is from a datasheet, mention the product name. For numerical specifications, format them clearly (e.g., 'Drain-Source Voltage: 60V'). If information is not found, clearly state that. When presenting catalog query results, format data in clean tables."
    },
    "tools": [
      {
        "tool_spec": {
          "type": "cortex_search",
          "name": "search_mcc_products",
          "description": "Search MCC product documentation including datasheets, reliability reports, package specifications, environmental statements, and soldering guides."
        }
      },
      {
        "tool_spec": {
          "type": "cortex_analyst_text_to_sql",
          "name": "query_product_catalog",
          "description": "Query the MCC product catalog database containing 43,000+ part numbers. Use for part availability, counts, lifecycle status, package types, electrical specs, and analytical questions."
        }
      }
    ],
    "tool_resources": {
      "search_mcc_products": {
        "search_service": "PRODUCT_DATA_AGENT.DATA.MCC_PRODUCT_SEARCH",
        "max_results": 5,
        "columns": ["chunk_text", "product_name", "document_type", "source_file"]
      },
      "query_product_catalog": {
        "semantic_view": "PRODUCT_DATA_AGENT.DATA.MCC_PRODUCT_CATALOG",
        "execution_environment": {
          "type": "warehouse",
          "warehouse": "WH_XS"
        }
      }
    }
  }
  $$;

-- Verify
SHOW AGENTS IN SCHEMA AGENTS;

-- Test the agent in Snowsight > AI & ML > Snowflake Intelligence
