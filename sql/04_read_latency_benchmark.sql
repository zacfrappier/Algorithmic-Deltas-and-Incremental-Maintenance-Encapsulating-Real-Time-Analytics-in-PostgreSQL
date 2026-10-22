-- ============================================================
-- A1: ON-THE-FLY VIEW
-- One warm-up run followed by three measured runs
-- ============================================================

-- Warm-up: do not record
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM vw_sla_on_the_fly
ORDER BY Hub_Region, Customer_Priority_Level;

-- Measured run 1
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM vw_sla_on_the_fly
ORDER BY Hub_Region, Customer_Priority_Level;

-- Measured run 2
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM vw_sla_on_the_fly
ORDER BY Hub_Region, Customer_Priority_Level;

-- Measured run 3
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM vw_sla_on_the_fly
ORDER BY Hub_Region, Customer_Priority_Level;


-- ============================================================
-- A2: PHYSICAL SUMMARY TABLE
-- One warm-up run followed by three measured runs
-- ============================================================

-- Warm-up: do not record
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM Fact_SLA_Region_Summary
ORDER BY Hub_Region, Priority_Level;

-- Measured run 1
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM Fact_SLA_Region_Summary
ORDER BY Hub_Region, Priority_Level;

-- Measured run 2
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM Fact_SLA_Region_Summary
ORDER BY Hub_Region, Priority_Level;

-- Measured run 3
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM Fact_SLA_Region_Summary
ORDER BY Hub_Region, Priority_Level;