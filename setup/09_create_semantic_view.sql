-- ============================================================================
-- Step 9: Create Semantic View
-- ============================================================================
-- Creates the MCC_PRODUCT_CATALOG Semantic View for Cortex Analyst
-- text-to-SQL querying over the product catalog.
-- ============================================================================

USE DATABASE PRODUCT_DATA_AGENT;
USE SCHEMA DATA;

CALL SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML('PRODUCT_DATA_AGENT.DATA',
$$name: MCC_PRODUCT_CATALOG
description: MCC (Micro Commercial Components) product catalog with part numbers, electrical specifications, package types, lifecycle status, and compliance data across diodes, MOSFETs, IGBTs, transistors, protection devices, and power modules.

tables:
  - name: PRODUCT_CATALOG
    description: Complete MCC semiconductor product catalog with 43,000+ part numbers including electrical specs, package info, lifecycle status, and compliance flags.
    base_table:
      database: PRODUCT_DATA_AGENT
      schema: DATA
      table: PRODUCT_CATALOG

    dimensions:
      - name: MPN
        description: Manufacturer Part Number - the unique identifier for each product
        expr: MPN
        data_type: VARCHAR
        synonyms:
          - part number
          - part
          - PN
          - MPN
          - SKU
          - manufacturing part number
          - manufacturer part number

      - name: PRODUCT_FAMILY
        description: Top-level product category grouping
        expr: PRODUCT_FAMILY
        data_type: VARCHAR
        sample_values:
          - Diodes
          - MOSFETs
          - IGBT
          - Transistors
          - Protection Devices
          - Power Modules
          - SIC SBD
          - Voltage Regulators
        synonyms:
          - family
          - product type
          - category

      - name: DESCRIPTION
        description: Short text description of the product type
        expr: DESCRIPTION
        data_type: VARCHAR

      - name: SUB_FAMILY
        description: More specific product sub-category within a product family
        expr: SUB_FAMILY
        data_type: VARCHAR
        sample_values:
          - TVS
          - Schottky Barrier Rectifiers
          - Power MOSFETS
          - Zener Diodes
          - Standard Recovery Rectifiers
          - Fast Recovery Rectifiers
          - Small Signal MOSFETS
          - Bridge Rectifiers
          - ESD Protection Devices
          - SIC MOSFETS
        synonyms:
          - sub-family
          - subcategory
          - sub category
          - product sub type

      - name: STATUS
        description: Product lifecycle status
        expr: STATUS
        data_type: VARCHAR
        sample_values:
          - Active
          - Obsoleted
          - NRND
          - P/N Change
          - EOL
          - Pre-Release
          - Allocation
          - PCN
          - Reactive
        synonyms:
          - lifecycle status
          - product status
          - part status

      - name: MPN_STATUS
        description: Duplicate of STATUS from a secondary data source - use STATUS instead
        expr: MPN_STATUS
        data_type: VARCHAR

      - name: PACKAGE_TYPE
        description: Physical package or case type of the component
        expr: PACKAGE_TYPE
        data_type: VARCHAR
        sample_values:
          - SOT-23
          - DO-201AE
          - TO-220AB
          - SMA
          - SOD-123
          - TO-247AB
          - D2-PAK
          - R-6
          - SMB
          - DPAK
        synonyms:
          - package
          - case
          - form factor
          - footprint

      - name: POLARITY
        description: Polarity of the device (e.g., N-Channel, P-Channel for MOSFETs)
        expr: POLARITY
        data_type: VARCHAR
        synonyms:
          - channel type

      - name: CHANNEL
        description: Channel configuration (e.g., single, dual)
        expr: CHANNEL
        data_type: VARCHAR

      - name: UOM
        description: Unit of measure (typically EA for each)
        expr: UOM
        data_type: VARCHAR

      - name: AECQ101_QUALIFIED
        description: Whether the part is AEC-Q101 automotive qualified
        expr: AECQ101_QUALIFIED
        data_type: VARCHAR
        sample_values:
          - "Yes"
          - "No"
        synonyms:
          - automotive qualified
          - AEC-Q101
          - AECQ

      - name: IS_PPAP_AVAILABLE
        description: Whether PPAP (Production Part Approval Process) documentation is available
        expr: IS_PPAP_AVAILABLE
        data_type: VARCHAR
        synonyms:
          - PPAP

      - name: DATASHEET_URL
        description: URL link to the product datasheet PDF
        expr: DATASHEET_URL
        data_type: VARCHAR
        synonyms:
          - datasheet
          - datasheet link

      - name: LEADTIME_UNITS
        description: Units for lead time (typically weeks)
        expr: LEADTIME_UNITS
        data_type: VARCHAR

      - name: TRANS_LINKAGE
        description: Transaction linkage type
        expr: TRANS_LINKAGE
        data_type: VARCHAR

      - name: REG_LINKAGE
        description: Registration linkage type
        expr: REG_LINKAGE
        data_type: VARCHAR

      - name: LAST_TIME_BUY
        description: Last time buy date for EOL or discontinued parts
        expr: LAST_TIME_BUY
        data_type: VARCHAR
        synonyms:
          - LTB

      - name: LAST_TIME_SHIP
        description: Last time ship date for EOL or discontinued parts
        expr: LAST_TIME_SHIP
        data_type: VARCHAR
        synonyms:
          - LTS

      - name: NPI_START
        description: New Product Introduction start date
        expr: NPI_START
        data_type: VARCHAR

      - name: NPI_END
        description: New Product Introduction end date
        expr: NPI_END
        data_type: VARCHAR

      - name: PART_CLASSIFICATION
        description: Classification of the part
        expr: PART_CLASSIFICATION
        data_type: VARCHAR

      - name: ABC_ANALYSIS
        description: ABC analysis classification for inventory management
        expr: ABC_ANALYSIS
        data_type: VARCHAR
        synonyms:
          - ABC class
          - inventory class

      - name: COO
        description: Country of origin
        expr: COO
        data_type: VARCHAR
        synonyms:
          - country of origin
          - origin

      - name: NON_CN_COO
        description: Non-China country of origin alternative
        expr: NON_CN_COO
        data_type: VARCHAR

      - name: NON_CN_COO_PLANNED_DATE
        description: Planned date for non-China country of origin availability
        expr: NON_CN_COO_PLANNED_DATE
        data_type: VARCHAR

      - name: ROOT
        description: Root part number
        expr: ROOT
        data_type: VARCHAR

      - name: BASE_PART
        description: Base part number
        expr: BASE_PART
        data_type: VARCHAR

      - name: CUSTOM_MPN
        description: Whether this is a custom MPN
        expr: CUSTOM_MPN
        data_type: BOOLEAN

    facts:
      - name: PD_W
        description: Power dissipation in watts
        expr: PD_W
        data_type: NUMBER
        synonyms:
          - power dissipation
          - wattage

      - name: VZ_V
        description: Zener voltage in volts
        expr: VZ_V
        data_type: NUMBER
        synonyms:
          - zener voltage

      - name: VDS_V
        description: Drain-source voltage in volts (for MOSFETs)
        expr: VDS_V
        data_type: VARCHAR
        synonyms:
          - drain source voltage
          - VDS

      - name: ID_A
        description: Drain current in amps (for MOSFETs)
        expr: ID_A
        data_type: VARCHAR
        synonyms:
          - drain current
          - ID

      - name: PC_W
        description: Collector power dissipation in watts
        expr: PC_W
        data_type: VARCHAR
        synonyms:
          - collector power

      - name: IC_A
        description: Collector current in amps
        expr: IC_A
        data_type: VARCHAR
        synonyms:
          - collector current
          - IC

      - name: IO_A
        description: Output current in amps
        expr: IO_A
        data_type: NUMBER
        synonyms:
          - output current

      - name: MAX_VO_V
        description: Maximum output voltage in volts
        expr: MAX_VO_V
        data_type: NUMBER
        synonyms:
          - max output voltage

      - name: VRWM_V
        description: Working peak reverse voltage in volts (for TVS diodes)
        expr: VRWM_V
        data_type: NUMBER
        synonyms:
          - reverse working voltage
          - VRWM
          - standoff voltage

      - name: FORWARD_CURRENT_IF
        description: Forward current (If) in amps
        expr: FORWARD_CURRENT_IF
        data_type: NUMBER
        synonyms:
          - forward current
          - If

      - name: FORWARD_VOLTAGE_VF
        description: Forward voltage drop (Vf) in volts
        expr: FORWARD_VOLTAGE_VF
        data_type: NUMBER
        synonyms:
          - forward voltage
          - Vf
          - voltage drop

      - name: VOLTAGE_CLASS_MAX_V
        description: Maximum voltage class rating in volts
        expr: VOLTAGE_CLASS_MAX_V
        data_type: NUMBER
        synonyms:
          - voltage class
          - max voltage

      - name: IC_100DEG_MAX_A
        description: Maximum collector current at 100 degrees C
        expr: IC_100DEG_MAX_A
        data_type: NUMBER

      - name: VR_V
        description: Reverse voltage in volts
        expr: VR_V
        data_type: NUMBER
        synonyms:
          - reverse voltage
          - VR

      - name: IS_ROOT
        description: Whether this is a root part number (1=yes, 0=no)
        expr: IS_ROOT
        data_type: NUMBER

      - name: CAN_SAMPLE
        description: Whether samples can be requested (1=yes, 0=no)
        expr: CAN_SAMPLE
        data_type: NUMBER

      - name: CAN_QUOTE
        description: Whether quotes can be requested (1=yes, 0=no)
        expr: CAN_QUOTE
        data_type: NUMBER

      - name: CAN_ORDER
        description: Whether the part can be ordered (1=yes, 0=no)
        expr: CAN_ORDER
        data_type: NUMBER

      - name: IS_NCNR
        description: Whether the part is non-cancellable non-returnable (1=yes, 0=no)
        expr: IS_NCNR
        data_type: NUMBER
        synonyms:
          - non-cancellable
          - NCNR

      - name: IS_NPI
        description: Whether this is a New Product Introduction
        expr: IS_NPI
        data_type: BOOLEAN
        synonyms:
          - new product

      - name: FOCUS_NPI
        description: Whether this is a focus NPI part
        expr: FOCUS_NPI
        data_type: BOOLEAN

      - name: DRY_PACK
        description: Whether dry pack packaging is required
        expr: DRY_PACK
        data_type: BOOLEAN

      - name: ANTI_STATIC
        description: Whether anti-static packaging is required
        expr: ANTI_STATIC
        data_type: BOOLEAN

    metrics:
      - name: TOTAL_PARTS
        description: Total number of part numbers
        expr: COUNT(*)
        synonyms:
          - part count
          - number of parts
          - how many parts

      - name: ACTIVE_PARTS
        description: Number of active part numbers
        expr: "COUNT_IF(STATUS = 'Active')"
        synonyms:
          - active count
          - active part count

      - name: OBSOLETE_PARTS
        description: Number of obsoleted part numbers
        expr: "COUNT_IF(STATUS = 'Obsoleted')"

    filters:
      - name: ACTIVE_ONLY
        description: Filter to only active parts
        expr: "STATUS = 'Active'"

      - name: NOT_OBSOLETE
        description: Exclude obsoleted parts
        expr: "STATUS != 'Obsoleted'"

      - name: AUTOMOTIVE_QUALIFIED
        description: Filter to AEC-Q101 automotive qualified parts only
        expr: "AECQ101_QUALIFIED = 'Yes'"

verified_queries:
  - name: vqr_0
    question: How many parts are there by product family?
    sql: |
      SELECT
        PRODUCT_FAMILY,
        COUNT(*) AS TOTAL_PARTS
      FROM PRODUCT_DATA_AGENT.DATA.PRODUCT_CATALOG
      GROUP BY PRODUCT_FAMILY
      ORDER BY TOTAL_PARTS DESC

  - name: vqr_1
    question: How many active parts are there by sub-family?
    sql: |
      SELECT
        SUB_FAMILY,
        COUNT(*) AS ACTIVE_PARTS
      FROM PRODUCT_DATA_AGENT.DATA.PRODUCT_CATALOG
      WHERE STATUS = 'Active'
      GROUP BY SUB_FAMILY
      ORDER BY ACTIVE_PARTS DESC

  - name: vqr_2
    question: What are the different product statuses and how many parts are in each?
    sql: |
      SELECT
        STATUS,
        COUNT(*) AS PART_COUNT
      FROM PRODUCT_DATA_AGENT.DATA.PRODUCT_CATALOG
      GROUP BY STATUS
      ORDER BY PART_COUNT DESC

  - name: vqr_3
    question: What package types are available for Power MOSFETs?
    sql: |
      SELECT
        PACKAGE_TYPE,
        COUNT(*) AS PART_COUNT
      FROM PRODUCT_DATA_AGENT.DATA.PRODUCT_CATALOG
      WHERE SUB_FAMILY = 'Power MOSFETS'
        AND STATUS = 'Active'
      GROUP BY PACKAGE_TYPE
      ORDER BY PART_COUNT DESC

  - name: vqr_4
    question: How many automotive qualified parts does MCC have?
    sql: |
      SELECT
        PRODUCT_FAMILY,
        COUNT(*) AS AEC_Q101_PARTS
      FROM PRODUCT_DATA_AGENT.DATA.PRODUCT_CATALOG
      WHERE AECQ101_QUALIFIED = 'Yes'
      GROUP BY PRODUCT_FAMILY
      ORDER BY AEC_Q101_PARTS DESC

  - name: vqr_5
    question: What are the active Schottky Barrier Rectifiers available in SOD-123 package?
    sql: |
      SELECT
        MPN,
        VR_V,
        FORWARD_CURRENT_IF,
        FORWARD_VOLTAGE_VF
      FROM PRODUCT_DATA_AGENT.DATA.PRODUCT_CATALOG
      WHERE SUB_FAMILY = 'Schottky Barrier Rectifiers'
        AND PACKAGE_TYPE = 'SOD-123'
        AND STATUS = 'Active'
      ORDER BY MPN
$$,
FALSE
);

-- Verify deployment
SHOW SEMANTIC VIEWS IN PRODUCT_DATA_AGENT.DATA;
DESC SEMANTIC VIEW PRODUCT_DATA_AGENT.DATA.MCC_PRODUCT_CATALOG;
