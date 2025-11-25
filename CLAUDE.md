# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Purpose

This repository contains Azure infrastructure and data assets for testing ekai's AI-assisted data migration feature. It sets up a source environment (Azure VM with SQL Server + SSIS) with the NORTHWIND dataset that ekai will migrate to Snowflake/DBT.

## Azure Environment

| Resource | Value |
|----------|-------|
| Subscription | `0d60f268-90d2-4a58-8edf-4e1bdd611d92` (ekai dev) |
| Resource Group | `ekai-magent-ssis` |
| Region | `East US 2` |
| VM Name | `ekai-magent-vm` |
| VM Size | `Standard_B2s` (~$30/month) |
| Public IP | `135.119.176.128` |
| SQL Server | SQL Server 2022 Developer Edition |
| SSIS | SQL Server Integration Services 2022 (MsDtsServer160) |

## Credentials

| Service | Username | Password |
|---------|----------|----------|
| VM (RDP) | `ekaiadmin` | `98AHZMdB8qmJUdSe` |
| SQL Server (sa) | `sa` | `98AHZMdB8qmJUdSe` |

## Repository Structure

```
/ssis-packages
  LoadCustomers.dtsx           - Extract customers with derived columns
  LoadOrdersWithLookup.dtsx    - Orders ETL with multiple lookups
  SalesSummaryAggregation.dtsx - Sales aggregation by category/month
```

## Connection Commands

```bash
# RDP to VM
open rdp://ekaiadmin@135.119.176.128

# Connect to SQL Server (from local machine)
sqlcmd -S 135.119.176.128 -U sa -P '98AHZMdB8qmJUdSe' -d Northwind

# Connect to SQL Server (on VM)
sqlcmd -S localhost -U sa -P '98AHZMdB8qmJUdSe' -d Northwind
```

## NORTHWIND Data

| Table | Rows |
|-------|------|
| Categories | 8 |
| Customers | 91 |
| Employees | 9 |
| Orders | 830 |
| Order Details | 2,155 |
| Products | 77 |
| Shippers | 3 |
| Suppliers | 29 |
| Territories | 53 |

## SSIS Packages Overview

### 1. LoadCustomers.dtsx
- **Control Flow:** Truncate → Data Flow → Log
- **Data Flow:** OLE DB Source → Derived Column → Row Count → OLE DB Destination
- **Transformations:** ISNULL handling, string concatenation (FullAddress)
- **Variables:** LoadDate, RowCount

### 2. LoadOrdersWithLookup.dtsx
- **Control Flow:** Create Tables → Data Flow
- **Data Flow:** Source → Lookup (Customers) → Lookup (Employees) → Lookup (Shippers) → Derived → Destination
- **Transformations:** Multiple lookups, date calculations (DaysToShip, IsLateShipment)
- **Variables:** StartDate, EndDate

### 3. SalesSummaryAggregation.dtsx
- **Control Flow:** Setup Tables → Parallel Aggregations (Category, Month)
- **Data Flow 1:** Source → Aggregate → Derived → Destination (Sales by Category)
- **Data Flow 2:** Source → Derived → Destination (Sales by Month)
- **Transformations:** GROUP BY aggregations (SUM, COUNT, AVG)
- **Variables:** ReportYear

## For ekai Migration Testing

ekai can connect to:
1. **SQL Server** at `135.119.176.128:1433` to read NORTHWIND schema/data
2. **SSIS packages** in `/ssis-packages/` directory to read ETL definitions
3. **VM via RDP** if needed to access SSIS catalog or run packages
