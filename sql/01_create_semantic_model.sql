-- =====================================================
-- NORTHWIND SEMANTIC MODEL - DATA WAREHOUSE SCHEMA
-- For ekai Migration Testing
-- =====================================================

USE Northwind;
GO

-- =====================================================
-- DIMENSION TABLES
-- =====================================================

-- Dim_Date - Calendar dimension
IF OBJECT_ID('dbo.Dim_Date', 'U') IS NOT NULL DROP TABLE dbo.Dim_Date;
CREATE TABLE dbo.Dim_Date (
    DateKey INT PRIMARY KEY,              -- YYYYMMDD format
    FullDate DATE NOT NULL,
    Year INT NOT NULL,
    Quarter INT NOT NULL,
    QuarterName VARCHAR(10) NOT NULL,     -- Q1, Q2, Q3, Q4
    Month INT NOT NULL,
    MonthName VARCHAR(20) NOT NULL,
    MonthShort VARCHAR(3) NOT NULL,       -- Jan, Feb, etc.
    Week INT NOT NULL,
    DayOfMonth INT NOT NULL,
    DayOfWeek INT NOT NULL,
    DayName VARCHAR(20) NOT NULL,
    DayShort VARCHAR(3) NOT NULL,         -- Mon, Tue, etc.
    IsWeekend BIT NOT NULL,
    IsHoliday BIT NOT NULL DEFAULT 0,
    FiscalYear INT NOT NULL,
    FiscalQuarter INT NOT NULL,
    LoadDate DATETIME DEFAULT GETDATE()
);
GO

-- Dim_Customer - Customer dimension with derived attributes
IF OBJECT_ID('dbo.Dim_Customer', 'U') IS NOT NULL DROP TABLE dbo.Dim_Customer;
CREATE TABLE dbo.Dim_Customer (
    CustomerKey INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID NCHAR(5) NOT NULL,
    CompanyName NVARCHAR(40) NOT NULL,
    ContactName NVARCHAR(30),
    ContactTitle NVARCHAR(30),
    Address NVARCHAR(60),
    City NVARCHAR(15),
    Region NVARCHAR(15),
    PostalCode NVARCHAR(10),
    Country NVARCHAR(15),
    Phone NVARCHAR(24),
    Fax NVARCHAR(24),
    -- Derived attributes
    CustomerSegment NVARCHAR(20),         -- High Value, Medium, Low
    GeographyRegion NVARCHAR(20),         -- Americas, Europe, etc.
    FirstOrderDate DATE,
    LastOrderDate DATE,
    TotalOrders INT DEFAULT 0,
    TotalRevenue MONEY DEFAULT 0,
    AvgOrderValue MONEY DEFAULT 0,
    CustomerLifetimeValue MONEY DEFAULT 0,
    DaysSinceLastOrder INT,
    -- SCD Type 2 fields
    EffectiveDate DATE NOT NULL,
    ExpirationDate DATE,
    IsCurrent BIT NOT NULL DEFAULT 1,
    LoadDate DATETIME DEFAULT GETDATE()
);
GO

-- Dim_Product - Product dimension with category hierarchy
IF OBJECT_ID('dbo.Dim_Product', 'U') IS NOT NULL DROP TABLE dbo.Dim_Product;
CREATE TABLE dbo.Dim_Product (
    ProductKey INT IDENTITY(1,1) PRIMARY KEY,
    ProductID INT NOT NULL,
    ProductName NVARCHAR(40) NOT NULL,
    -- Category hierarchy
    CategoryID INT,
    CategoryName NVARCHAR(15),
    CategoryDescription NVARCHAR(MAX),
    -- Supplier info
    SupplierID INT,
    SupplierName NVARCHAR(40),
    SupplierCountry NVARCHAR(15),
    SupplierRegion NVARCHAR(15),
    -- Product attributes
    QuantityPerUnit NVARCHAR(20),
    UnitPrice MONEY,
    UnitsInStock SMALLINT,
    UnitsOnOrder SMALLINT,
    ReorderLevel SMALLINT,
    Discontinued BIT,
    -- Derived attributes
    PriceRange NVARCHAR(20),              -- Budget, Mid-Range, Premium
    StockStatus NVARCHAR(20),             -- In Stock, Low Stock, Out of Stock
    InventoryValue MONEY,
    -- SCD fields
    EffectiveDate DATE NOT NULL,
    ExpirationDate DATE,
    IsCurrent BIT NOT NULL DEFAULT 1,
    LoadDate DATETIME DEFAULT GETDATE()
);
GO

-- Dim_Employee - Employee dimension with hierarchy
IF OBJECT_ID('dbo.Dim_Employee', 'U') IS NOT NULL DROP TABLE dbo.Dim_Employee;
CREATE TABLE dbo.Dim_Employee (
    EmployeeKey INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID INT NOT NULL,
    FullName NVARCHAR(50) NOT NULL,
    FirstName NVARCHAR(20),
    LastName NVARCHAR(20),
    Title NVARCHAR(30),
    TitleOfCourtesy NVARCHAR(25),
    BirthDate DATE,
    HireDate DATE,
    Address NVARCHAR(60),
    City NVARCHAR(15),
    Region NVARCHAR(15),
    PostalCode NVARCHAR(10),
    Country NVARCHAR(15),
    HomePhone NVARCHAR(24),
    Extension NVARCHAR(4),
    -- Manager hierarchy
    ReportsToID INT,
    ReportsToName NVARCHAR(50),
    IsManager BIT DEFAULT 0,
    ManagementLevel INT DEFAULT 0,        -- 0=Staff, 1=Manager, 2=Director, etc.
    -- Derived attributes
    YearsOfService INT,
    AgeAtHire INT,
    TerritoryCount INT DEFAULT 0,
    -- SCD fields
    EffectiveDate DATE NOT NULL,
    ExpirationDate DATE,
    IsCurrent BIT NOT NULL DEFAULT 1,
    LoadDate DATETIME DEFAULT GETDATE()
);
GO

-- Dim_Geography - Geography dimension (denormalized from customers)
IF OBJECT_ID('dbo.Dim_Geography', 'U') IS NOT NULL DROP TABLE dbo.Dim_Geography;
CREATE TABLE dbo.Dim_Geography (
    GeographyKey INT IDENTITY(1,1) PRIMARY KEY,
    Country NVARCHAR(15) NOT NULL,
    Region NVARCHAR(15),
    City NVARCHAR(15),
    GeographyRegion NVARCHAR(20),         -- Americas, Europe, Asia-Pacific
    LoadDate DATETIME DEFAULT GETDATE()
);
GO

-- =====================================================
-- FACT TABLES
-- =====================================================

-- Fact_Sales - Main sales fact table (grain: order line item)
IF OBJECT_ID('dbo.Fact_Sales', 'U') IS NOT NULL DROP TABLE dbo.Fact_Sales;
CREATE TABLE dbo.Fact_Sales (
    SalesKey BIGINT IDENTITY(1,1) PRIMARY KEY,
    -- Foreign Keys
    OrderID INT NOT NULL,
    DateKey INT NOT NULL,
    CustomerKey INT NOT NULL,
    ProductKey INT NOT NULL,
    EmployeeKey INT NOT NULL,
    -- Degenerate dimensions
    OrderLineNumber INT NOT NULL,
    -- Measures
    Quantity SMALLINT NOT NULL,
    UnitPrice MONEY NOT NULL,
    Discount REAL NOT NULL,
    -- Calculated measures
    GrossAmount MONEY NOT NULL,           -- UnitPrice * Quantity
    DiscountAmount MONEY NOT NULL,        -- GrossAmount * Discount
    NetAmount MONEY NOT NULL,             -- GrossAmount - DiscountAmount
    -- Order-level attributes (for analysis)
    OrderFreight MONEY,
    FreightAllocation MONEY,              -- Freight allocated to this line
    -- Dates for analysis
    OrderDate DATE,
    RequiredDate DATE,
    ShippedDate DATE,
    DaysToShip INT,
    DaysLate INT,                         -- Days past RequiredDate
    IsLateShipment BIT,
    LoadDate DATETIME DEFAULT GETDATE()
);
GO

-- Fact_OrderSnapshot - Daily order snapshot for trending
IF OBJECT_ID('dbo.Fact_OrderSnapshot', 'U') IS NOT NULL DROP TABLE dbo.Fact_OrderSnapshot;
CREATE TABLE dbo.Fact_OrderSnapshot (
    SnapshotKey BIGINT IDENTITY(1,1) PRIMARY KEY,
    DateKey INT NOT NULL,
    -- Measures
    TotalOrders INT NOT NULL,
    TotalOrderValue MONEY NOT NULL,
    TotalFreight MONEY NOT NULL,
    AvgOrderValue MONEY NOT NULL,
    TotalLineItems INT NOT NULL,
    UniqueCustomers INT NOT NULL,
    UniqueProducts INT NOT NULL,
    -- Shipping metrics
    OrdersShipped INT NOT NULL,
    OrdersPending INT NOT NULL,
    AvgDaysToShip DECIMAL(10,2),
    LateShipmentCount INT NOT NULL,
    LateShipmentPct DECIMAL(5,2),
    LoadDate DATETIME DEFAULT GETDATE()
);
GO

-- =====================================================
-- AGGREGATION TABLES (for KPIs and reporting)
-- =====================================================

-- Agg_SalesByCategory - Pre-aggregated sales by category
IF OBJECT_ID('dbo.Agg_SalesByCategory', 'U') IS NOT NULL DROP TABLE dbo.Agg_SalesByCategory;
CREATE TABLE dbo.Agg_SalesByCategory (
    AggKey BIGINT IDENTITY(1,1) PRIMARY KEY,
    Year INT NOT NULL,
    Quarter INT NOT NULL,
    Month INT NOT NULL,
    CategoryID INT NOT NULL,
    CategoryName NVARCHAR(15) NOT NULL,
    -- Measures
    TotalQuantity INT NOT NULL,
    TotalGrossAmount MONEY NOT NULL,
    TotalDiscountAmount MONEY NOT NULL,
    TotalNetAmount MONEY NOT NULL,
    OrderCount INT NOT NULL,
    AvgUnitPrice MONEY NOT NULL,
    AvgDiscount DECIMAL(5,2) NOT NULL,
    -- Rankings
    CategoryRankByRevenue INT,
    CategoryRankByQuantity INT,
    LoadDate DATETIME DEFAULT GETDATE()
);
GO

-- Agg_SalesByCustomer - Customer performance aggregation
IF OBJECT_ID('dbo.Agg_SalesByCustomer', 'U') IS NOT NULL DROP TABLE dbo.Agg_SalesByCustomer;
CREATE TABLE dbo.Agg_SalesByCustomer (
    AggKey BIGINT IDENTITY(1,1) PRIMARY KEY,
    Year INT NOT NULL,
    CustomerKey INT NOT NULL,
    CustomerID NCHAR(5) NOT NULL,
    CompanyName NVARCHAR(40) NOT NULL,
    Country NVARCHAR(15),
    -- Measures
    TotalOrders INT NOT NULL,
    TotalQuantity INT NOT NULL,
    TotalNetAmount MONEY NOT NULL,
    TotalFreight MONEY NOT NULL,
    AvgOrderValue MONEY NOT NULL,
    AvgDaysToShip DECIMAL(10,2),
    -- Customer metrics
    UniqueProductsOrdered INT,
    UniqueCategoriesOrdered INT,
    -- Rankings
    CustomerRankByRevenue INT,
    CustomerRankByOrders INT,
    LoadDate DATETIME DEFAULT GETDATE()
);
GO

-- Agg_EmployeePerformance - Employee sales performance
IF OBJECT_ID('dbo.Agg_EmployeePerformance', 'U') IS NOT NULL DROP TABLE dbo.Agg_EmployeePerformance;
CREATE TABLE dbo.Agg_EmployeePerformance (
    AggKey BIGINT IDENTITY(1,1) PRIMARY KEY,
    Year INT NOT NULL,
    Quarter INT NOT NULL,
    EmployeeKey INT NOT NULL,
    EmployeeID INT NOT NULL,
    FullName NVARCHAR(50) NOT NULL,
    Title NVARCHAR(30),
    -- Measures
    TotalOrders INT NOT NULL,
    TotalCustomers INT NOT NULL,
    TotalNetAmount MONEY NOT NULL,
    TotalFreight MONEY NOT NULL,
    AvgOrderValue MONEY NOT NULL,
    LateShipmentCount INT NOT NULL,
    OnTimeDeliveryPct DECIMAL(5,2),
    -- Rankings
    EmployeeRankByRevenue INT,
    EmployeeRankByOrders INT,
    LoadDate DATETIME DEFAULT GETDATE()
);
GO

-- =====================================================
-- ETL CONTROL TABLES
-- =====================================================

-- ETL_Log - Package execution logging
IF OBJECT_ID('dbo.ETL_Log', 'U') IS NOT NULL DROP TABLE dbo.ETL_Log;
CREATE TABLE dbo.ETL_Log (
    LogID BIGINT IDENTITY(1,1) PRIMARY KEY,
    PackageName NVARCHAR(100) NOT NULL,
    TaskName NVARCHAR(100),
    StartTime DATETIME NOT NULL,
    EndTime DATETIME,
    Status NVARCHAR(20) NOT NULL,         -- Running, Succeeded, Failed
    RowsRead INT DEFAULT 0,
    RowsInserted INT DEFAULT 0,
    RowsUpdated INT DEFAULT 0,
    RowsDeleted INT DEFAULT 0,
    ErrorMessage NVARCHAR(MAX),
    ExecutionID UNIQUEIDENTIFIER DEFAULT NEWID()
);
GO

-- ETL_WaterMark - High watermark for incremental loads
IF OBJECT_ID('dbo.ETL_WaterMark', 'U') IS NOT NULL DROP TABLE dbo.ETL_WaterMark;
CREATE TABLE dbo.ETL_WaterMark (
    WaterMarkID INT IDENTITY(1,1) PRIMARY KEY,
    TableName NVARCHAR(100) NOT NULL,
    ColumnName NVARCHAR(100) NOT NULL,
    LastValue NVARCHAR(100) NOT NULL,
    LastLoadDate DATETIME NOT NULL,
    CONSTRAINT UQ_WaterMark UNIQUE (TableName, ColumnName)
);
GO

PRINT 'Semantic model schema created successfully';
PRINT 'Tables created: Dim_Date, Dim_Customer, Dim_Product, Dim_Employee, Dim_Geography';
PRINT 'Fact tables: Fact_Sales, Fact_OrderSnapshot';
PRINT 'Aggregations: Agg_SalesByCategory, Agg_SalesByCustomer, Agg_EmployeePerformance';
PRINT 'ETL tables: ETL_Log, ETL_WaterMark';
GO
