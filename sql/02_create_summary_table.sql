-- ============================================================
-- 02_create_summary_table.sql
-- Purpose:
-- Creates the physical summary table used for Incremental View
-- Maintenance (IVM).
--
-- Instead of recalculating SLA violations from Route_Logs,
-- Deliveries, Hubs, and Customers every time, the dashboard can
-- read directly from this small summary table.
--
-- Grouping level:
-- Hub_Region + Customer_Priority_Level
-- ============================================================

DROP TABLE IF EXISTS Fact_SLA_Region_Summary;

CREATE TABLE Fact_SLA_Region_Summary (
    Hub_Region VARCHAR(50) NOT NULL,
    Priority_Level VARCHAR(50) NOT NULL,
    Total_Violations INT NOT NULL DEFAULT 0,
    Total_Penalty_Cost NUMERIC(14,2) NOT NULL DEFAULT 0.00,

    PRIMARY KEY (Hub_Region, Priority_Level)
);