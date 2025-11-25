# Northwind SSIS Semantic Model

Test case for ekai migration tool - SQL Server/SSIS to Snowflake/DBT.

## Files

```
sql/
  01_create_semantic_model.sql    -- Creates DW schema (dimensions, facts, aggregations)

ssis-packages/
  00_Master_ETL_Orchestration.dtsx  -- Master package (calls all others)
  01_Load_Dim_Date.dtsx             -- Date dimension (CTE generator)
  02_Load_Dim_Customer.dtsx         -- Customer dimension (SCD Type 2)
  03_Load_Dim_Product.dtsx          -- Product dimension (derived columns)
  04_Load_Dim_Employee.dtsx         -- Employee dimension (hierarchy)
  05_Load_Fact_Sales.dtsx           -- Fact table (dimension lookups)
  06_Build_Aggregations.dtsx        -- KPI aggregations (window functions)
```

## Tables Created

**Dimensions:** Dim_Date, Dim_Customer, Dim_Product, Dim_Employee, Dim_Geography

**Facts:** Fact_Sales, Fact_OrderSnapshot

**Aggregations:** Agg_SalesByCategory, Agg_SalesByCustomer, Agg_EmployeePerformance

## Source Data

Northwind sample database from Microsoft:
https://github.com/microsoft/sql-server-samples/tree/master/samples/databases/northwind-pubs
