# SSIS Migration Test Case - Northwind Semantic Model

This repository contains a complete SSIS-based ETL solution for a Northwind data warehouse semantic model. It is designed as a test case for the ekai data migration tool, demonstrating migration from SQL Server/SSIS to modern cloud platforms.

## Architecture

### Star Schema Design

```
                    +------------------+
                    |    Dim_Date      |
                    +------------------+
                           |
+------------------+       |       +------------------+
|  Dim_Customer    |-------+-------|   Dim_Product    |
+------------------+       |       +------------------+
                           |
                    +------+------+
                    |  Fact_Sales |
                    +------+------+
                           |
                    +------------------+
                    |  Dim_Employee    |
                    +------------------+
```

### Dimension Tables
- **Dim_Date** - Date dimension with fiscal calendar, holiday flags, and time intelligence
- **Dim_Customer** - Customer dimension with SCD Type 2 support for tracking changes
- **Dim_Product** - Product dimension with derived pricing tiers and stock status
- **Dim_Employee** - Employee dimension with organizational hierarchy

### Fact Tables
- **Fact_Sales** - Order line item grain with pre-calculated measures
- **Fact_OrderSnapshot** - Daily order aggregates for trending analysis

### Aggregation Tables
- **Agg_SalesByCategory** - Category-level sales performance
- **Agg_SalesByCustomer** - Customer-level revenue metrics
- **Agg_EmployeePerformance** - Employee sales performance by quarter

## SSIS Packages

### Master Orchestration
- `00_Master_ETL_Orchestration.dtsx` - Orchestrates entire ETL flow

### Dimension Loads
- `01_Load_Dim_Date.dtsx` - Date dimension generator (CTE-based)
- `02_Load_Dim_Customer.dtsx` - Customer with SCD Type 2 handling
- `03_Load_Dim_Product.dtsx` - Product with derived columns and conditional splits
- `04_Load_Dim_Employee.dtsx` - Employee with hierarchy attributes

### Fact Table Loads
- `05_Load_Fact_Sales.dtsx` - Fact table with 4 dimension lookups, incremental load support

### Aggregations
- `06_Build_Aggregations.dtsx` - Parallel aggregation builds with window functions

## ETL Flow

```
Initialize ETL Run
       |
       v
Load Dimensions
  +-> Dim_Date (first)
  |      |
  |      v
  +-> Dim_Customer ----+
  +-> Dim_Product  ----|  (parallel)
  +-> Dim_Employee ----+
       |
       v
Load Fact Tables
  +-> Fact_Sales
       |
       v
Build Aggregations
  +-> Agg_SalesByCategory ----+
  +-> Agg_SalesByCustomer ----|  (parallel)
  +-> Agg_EmployeePerformance +
  +-> Fact_OrderSnapshot
       |
       v
Finalize ETL Run
```

## Key SSIS Features Demonstrated

1. **Data Flow Components**
   - OLE DB Source with SQL commands
   - Derived Column transformations
   - Lookup transformations (dimension keys)
   - Conditional Split
   - Union All
   - Row Count
   - OLE DB Destination with fast load

2. **Control Flow Components**
   - Execute SQL Task
   - Execute Package Task
   - Sequence Container (for parallel execution)
   - Precedence Constraints

3. **Advanced Patterns**
   - SCD Type 2 (Slowly Changing Dimension)
   - Incremental loads with watermarks
   - Parallel package execution
   - ETL logging and auditing
   - Error handling

## Azure Environment

- **VM**: ekai-magent-vm (Standard_B2s)
- **IP**: 135.119.176.128
- **SQL Server**: SQL Server 2022 Developer Edition
- **Database**: Northwind
- **SSIS**: SQL Server Integration Services 2022

## Deployment

1. Run `sql/01_create_semantic_model.sql` to create schema
2. Deploy SSIS packages to SQL Server
3. Execute `00_Master_ETL_Orchestration.dtsx`

## Source Data

Uses Microsoft's official Northwind sample database:
https://github.com/microsoft/sql-server-samples/tree/master/samples/databases/northwind-pubs
