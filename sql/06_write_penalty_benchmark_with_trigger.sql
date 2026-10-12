-- ============================================================
-- 06_write_penalty_benchmark_with_trigger.sql
-- Purpose:
-- Benchmark write performance when the IVM trigger is enabled.
--
-- Test B2: Write benchmark WITH trigger maintenance.
-- This measures the slower write path where PostgreSQL inserts
-- Route_Logs rows and also updates Fact_SLA_Region_Summary.
--
-- Record the "Execution Time" from EXPLAIN ANALYZE.
-- ============================================================

-- Make sure the IVM trigger is enabled.
ALTER TABLE Route_Logs
ENABLE TRIGGER trg_ivm_sla_update;

-- Clean up this benchmark range in case the script is rerun.
-- Important: this trigger only handles INSERT and UPDATE, not DELETE.
-- So after cleanup, rebuild the summary table from the baseline view.
DELETE FROM Route_Logs
WHERE Route_ID BETWEEN 700001 AND 710000;

TRUNCATE TABLE Fact_SLA_Region_Summary;

INSERT INTO Fact_SLA_Region_Summary (
    Hub_Region,
    Priority_Level,
    Total_Violations,
    Total_Penalty_Cost
)
SELECT
    Hub_Region,
    Customer_Priority_Level,
    Total_Violations,
    Total_Penalty_Cost
FROM vw_sla_on_the_fly;

-- ============================================================
-- Insert 10,000 new Route_Logs rows with trigger overhead.
--
-- Route_ID range:
-- 700001 through 710000
--
-- Because the trigger is enabled, each inserted violation row
-- incrementally updates Fact_SLA_Region_Summary.
-- ============================================================

EXPLAIN (ANALYZE, BUFFERS)
INSERT INTO Route_Logs (
    Route_ID,
    Delivery_ID,
    Vehicle_ID,
    Driver_ID,
    Weather_ID,
    Route_Distance,
    Delay_Minutes
)
SELECT
    700000 + gs AS Route_ID,
    gs AS Delivery_ID,
    ((gs - 1) % 5) + 1 AS Vehicle_ID,
    ((gs - 1) % 500) + 1 AS Driver_ID,
    ((gs - 1) % 4) + 1 AS Weather_ID,
    ROUND((random() * 490 + 10)::NUMERIC, 2) AS Route_Distance,
    FLOOR(random() * 120)::INT AS Delay_Minutes
FROM generate_series(1, 10000) AS gs;

-- Confirm that exactly 10,000 benchmark rows were inserted.
SELECT COUNT(*) AS inserted_rows_with_trigger
FROM Route_Logs
WHERE Route_ID BETWEEN 700001 AND 710000;

-- Confirm that the summary table was maintained.
SELECT *
FROM Fact_SLA_Region_Summary
ORDER BY
    Hub_Region,
    Priority_Level;

-- Optional correctness check:
-- The trigger-maintained summary table should match the baseline view.
SELECT *
FROM vw_sla_on_the_fly
ORDER BY
    Hub_Region,
    Customer_Priority_Level;