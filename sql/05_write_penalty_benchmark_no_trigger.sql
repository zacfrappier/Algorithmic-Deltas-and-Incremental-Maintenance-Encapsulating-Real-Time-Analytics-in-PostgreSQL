-- ============================================================
-- 05_write_penalty_benchmark_no_trigger.sql
-- Purpose:
-- Benchmark write performance when the IVM trigger is disabled.
--
-- Test B1: Write benchmark WITHOUT trigger maintenance.
-- This measures the faster write path where PostgreSQL only
-- inserts Route_Logs rows and does not update the summary table.
--
-- Record the "Execution Time" from EXPLAIN ANALYZE.
-- ============================================================

-- Make sure the IVM trigger is disabled for this benchmark.
ALTER TABLE Route_Logs
DISABLE TRIGGER trg_ivm_sla_update;

-- Clean up this benchmark range in case the script is rerun.
DELETE FROM Route_Logs
WHERE Route_ID BETWEEN 600001 AND 610000;

-- ============================================================
-- Insert 10,000 new Route_Logs rows without trigger overhead.
--
-- Route_ID range:
-- 600001 through 610000
--
-- Delivery_ID values:
-- 1 through 10000, which already exist in the Deliveries table.
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
    600000 + gs AS Route_ID,
    gs AS Delivery_ID,
    ((gs - 1) % 5) + 1 AS Vehicle_ID,
    ((gs - 1) % 500) + 1 AS Driver_ID,
    ((gs - 1) % 4) + 1 AS Weather_ID,
    ROUND((random() * 490 + 10)::NUMERIC, 2) AS Route_Distance,
    FLOOR(random() * 120)::INT AS Delay_Minutes
FROM generate_series(1, 10000) AS gs;

-- Confirm that exactly 10,000 benchmark rows were inserted.
SELECT COUNT(*) AS inserted_rows_without_trigger
FROM Route_Logs
WHERE Route_ID BETWEEN 600001 AND 610000;

-- ============================================================
-- Cleanup:
-- Remove the benchmark rows so the next test starts from a clean
-- baseline. The trigger is still disabled here, so this DELETE does
-- not affect the summary table.
-- ============================================================

DELETE FROM Route_Logs
WHERE Route_ID BETWEEN 600001 AND 610000;

-- Re-enable the trigger so the database returns to normal behavior.
ALTER TABLE Route_Logs
ENABLE TRIGGER trg_ivm_sla_update;