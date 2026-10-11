-- ============================================================
-- 01_baseline_query.sql
-- Purpose:
-- Creates the legacy SLA analytics view.
-- This view calculates SLA violations by joining base tables
-- every time the dashboard query is executed.
--
-- SLA rule:
-- A violation occurs when Route_Logs.Delay_Minutes > 60.
--
-- Penalty assumption:
-- Total_Penalty_Cost = (Delay_Minutes - 60) * 10.00
-- Meaning: $10 penalty for each minute beyond the 60-minute SLA.
-- ============================================================

DROP VIEW IF EXISTS vw_sla_on_the_fly;

CREATE VIEW vw_sla_on_the_fly AS
SELECT
    h.Hub_Region,
    c.Customer_Priority_Level,
    COUNT(*) AS Total_Violations,
    ROUND(SUM((r.Delay_Minutes - 60) * 10.00), 2) AS Total_Penalty_Cost
FROM Route_Logs r
JOIN Deliveries d
    ON r.Delivery_ID = d.Delivery_ID
JOIN Hubs h
    ON d.Hub_ID = h.Hub_ID
JOIN Customers c
    ON d.Customer_ID = c.Customer_ID
WHERE r.Delay_Minutes > 60
GROUP BY
    h.Hub_Region,
    c.Customer_Priority_Level
ORDER BY
    h.Hub_Region,
    c.Customer_Priority_Level;