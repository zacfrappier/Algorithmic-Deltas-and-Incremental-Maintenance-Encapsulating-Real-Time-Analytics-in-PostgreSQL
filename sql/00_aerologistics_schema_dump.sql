-- ==============================================================================
-- AeroLogistics Global: Normalized Schema & Synthetic Data Generator
-- Target RDBMS: PostgreSQL
-- Description: Generates an 8-table 3NF schema and populates it with 
--              500,000 mock delivery records for OLTP vs OLAP benchmarking.
-- ==============================================================================

-- 1. DROP EXISTING wk 7 objects (Reset Schema)
DROP VIEW IF EXISTS vw_regional_delivery_performance CASCADE;
DROP PROCEDURE IF EXISTS sp_dispatch_delivery(INT, INT, INT, INT, INT, INT, NUMERIC, NUMERIC);
DROP FUNCTION IF EXISTS fn_audit_severe_delay() CASCADE;
DROP TABLE IF EXISTS Severe_Delay_Audit CASCADE;

-- 1. DROP EXISTING TABLES (Reset Schema)
DROP TABLE IF EXISTS Route_Logs CASCADE;
DROP TABLE IF EXISTS Packages CASCADE;
DROP TABLE IF EXISTS Deliveries CASCADE;
DROP TABLE IF EXISTS Weather_Incidents CASCADE;
DROP TABLE IF EXISTS Customers CASCADE;
DROP TABLE IF EXISTS Drivers CASCADE;
DROP TABLE IF EXISTS Vehicles CASCADE;
DROP TABLE IF EXISTS Hubs CASCADE;
DROP TABLE IF EXISTS Route_Logs CASCADE;
DROP TABLE IF EXISTS Packages CASCADE;
DROP TABLE IF EXISTS Deliveries CASCADE;
DROP TABLE IF EXISTS Weather_Incidents CASCADE;
DROP TABLE IF EXISTS Customers CASCADE;
DROP TABLE IF EXISTS Drivers CASCADE;
DROP TABLE IF EXISTS Vehicles CASCADE;
DROP TABLE IF EXISTS Hubs CASCADE;

-- ==============================================================================
-- 2. DDL: CONSTRUCT NORMALIZED SCHEMA
-- ==============================================================================

CREATE TABLE Hubs (
    Hub_ID INT PRIMARY KEY,
    Hub_Name VARCHAR(100) NOT NULL,
    Hub_Region VARCHAR(50) NOT NULL
);

CREATE TABLE Vehicles (
    Vehicle_ID INT PRIMARY KEY,
    Vehicle_Type VARCHAR(50) NOT NULL
);

CREATE TABLE Drivers (
    Driver_ID INT PRIMARY KEY,
    Driver_Name VARCHAR(100) NOT NULL
);

CREATE TABLE Customers (
    Customer_ID INT PRIMARY KEY,
    Customer_Name VARCHAR(100) NOT NULL,
    Customer_Priority_Level VARCHAR(50) NOT NULL
);

CREATE TABLE Weather_Incidents (
    Weather_ID INT PRIMARY KEY,
    Weather_Severity VARCHAR(50) NOT NULL
);

CREATE TABLE Deliveries (
    Delivery_ID INT PRIMARY KEY,
    Hub_ID INT NOT NULL,
    Customer_ID INT NOT NULL,
    Delivery_Date DATE NOT NULL,
    FOREIGN KEY (Hub_ID) REFERENCES Hubs(Hub_ID),
    FOREIGN KEY (Customer_ID) REFERENCES Customers(Customer_ID)
);

CREATE TABLE Packages (
    Package_ID INT PRIMARY KEY,
    Delivery_ID INT NOT NULL,
    Package_Weight DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (Delivery_ID) REFERENCES Deliveries(Delivery_ID)
);

CREATE TABLE Route_Logs (
    Route_ID INT PRIMARY KEY,
    Delivery_ID INT NOT NULL,
    Vehicle_ID INT NOT NULL,
    Driver_ID INT NOT NULL,
    Weather_ID INT NOT NULL,
    Route_Distance DECIMAL(10, 2) NOT NULL,
    Delay_Minutes INT NOT NULL,
    FOREIGN KEY (Delivery_ID) REFERENCES Deliveries(Delivery_ID),
    FOREIGN KEY (Vehicle_ID) REFERENCES Vehicles(Vehicle_ID),
    FOREIGN KEY (Driver_ID) REFERENCES Drivers(Driver_ID),
    FOREIGN KEY (Weather_ID) REFERENCES Weather_Incidents(Weather_ID)
);

-- ==============================================================================
-- 3. DML: POPULATE LOOKUP DIMENSION TABLES
-- ==============================================================================

INSERT INTO Hubs (Hub_ID, Hub_Name, Hub_Region) VALUES 
(1, 'Seattle Alpha', 'Northwest'), (2, 'Dallas Central', 'South'), 
(3, 'New York East', 'Northeast'), (4, 'Chicago Prime', 'Midwest'), 
(5, 'Los Angeles Hub', 'West');

INSERT INTO Vehicles (Vehicle_ID, Vehicle_Type) VALUES 
(1, 'Heavy Freight'), (2, 'Light Van'), (3, 'Drone'), 
(4, 'Electric Step-Van'), (5, 'Cargo Plane');

INSERT INTO Weather_Incidents (Weather_ID, Weather_Severity) VALUES 
(1, 'Clear'), (2, 'Moderate'), (3, 'Severe'), (4, 'Critical');

-- Generate 500 Mock Drivers
INSERT INTO Drivers (Driver_ID, Driver_Name)
SELECT 
    generate_series(1, 500), 
    'Driver_' || generate_series(1, 500);

-- Generate 50,000 Mock Customers with randomized priority levels
INSERT INTO Customers (Customer_ID, Customer_Name, Customer_Priority_Level)
SELECT 
    id, 
    'Customer_' || id, 
    (ARRAY['Low', 'Standard', 'High'])[floor(random() * 3 + 1)]
FROM generate_series(1, 50000) AS id;

-- ==============================================================================
-- 4. DML: SYNTHESIZE 500,000 FACT RECORDS (DELIVERIES, PACKAGES, ROUTES)
-- ==============================================================================

-- Generate 500,000 Deliveries
INSERT INTO Deliveries (Delivery_ID, Hub_ID, Customer_ID, Delivery_Date)
SELECT 
    id,
    floor(random() * 5 + 1)::INT,                     -- Random Hub (1-5)
    floor(random() * 50000 + 1)::INT,                 -- Random Customer (1-50,000)
    CURRENT_DATE - (floor(random() * 365)::INT)       -- Random date in past year
FROM generate_series(1, 500000) AS id;

-- Generate 600,000 Packages (Some deliveries have multiple packages)
INSERT INTO Packages (Package_ID, Delivery_ID, Package_Weight)
SELECT 
    id,
    floor(random() * 500000 + 1)::INT,                -- Link to random Delivery
    ROUND((random() * 95 + 5)::NUMERIC, 2)            -- Random weight between 5.00 and 100.00
FROM generate_series(1, 600000) AS id;

-- Generate 500,000 Route Logs (1:1 with Deliveries for this simulation)
INSERT INTO Route_Logs (Route_ID, Delivery_ID, Vehicle_ID, Driver_ID, Weather_ID, Route_Distance, Delay_Minutes)
SELECT 
    id,
    id,                                               -- 1:1 Link to Delivery
    floor(random() * 5 + 1)::INT,                     -- Random Vehicle (1-5)
    floor(random() * 500 + 1)::INT,                   -- Random Driver (1-500)
    floor(random() * 4 + 1)::INT,                     -- Random Weather (1-4)
    ROUND((random() * 490 + 10)::NUMERIC, 2),         -- Random distance 10.00 - 500.00
    floor(random() * 120)::INT                        -- Random delay 0 - 120 minutes
FROM generate_series(1, 500000) AS id;

-- ==============================================================================
-- 5. OPTIMIZATION: GENERATE STATISTICS FOR QUERY PLANNER
-- ==============================================================================
ANALYZE Hubs;
ANALYZE Vehicles;
ANALYZE Drivers;
ANALYZE Customers;
ANALYZE Weather_Incidents;
ANALYZE Deliveries;
ANALYZE Packages;
ANALYZE Route_Logs;

-- Script Complete. Database is ready!