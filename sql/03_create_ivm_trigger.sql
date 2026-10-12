-- ============================================================
-- 03_create_ivm_trigger.sql
-- Purpose:
-- Creates the Incremental View Maintenance (IVM) trigger.
--
-- Instead of fully recomputing the SLA dashboard, this trigger
-- applies only the delta caused by a new or updated Route_Logs row.
--
-- SLA rule:
-- A violation occurs when Delay_Minutes > 60.
--
-- Penalty rule:
-- Total_Penalty_Cost = (Delay_Minutes - 60) * 10.00
-- ============================================================

CREATE OR REPLACE FUNCTION fn_ivm_sla_update()
RETURNS TRIGGER AS $$
DECLARE
    v_hub_region VARCHAR(50);
    v_priority_level VARCHAR(50);
    v_penalty NUMERIC(14,2);
BEGIN

    -- ========================================================
    -- If this is an UPDATE, remove the OLD row's contribution
    -- from the summary table if the old row was an SLA violation.
    -- ========================================================

    IF TG_OP = 'UPDATE' AND OLD.Delay_Minutes > 60 THEN

        SELECT
            h.Hub_Region,
            c.Customer_Priority_Level
        INTO
            v_hub_region,
            v_priority_level
        FROM Deliveries d
        JOIN Hubs h
            ON d.Hub_ID = h.Hub_ID
        JOIN Customers c
            ON d.Customer_ID = c.Customer_ID
        WHERE d.Delivery_ID = OLD.Delivery_ID;

        v_penalty := ROUND(((OLD.Delay_Minutes - 60) * 10.00)::NUMERIC, 2);

        UPDATE Fact_SLA_Region_Summary
        SET
            Total_Violations = Total_Violations - 1,
            Total_Penalty_Cost = Total_Penalty_Cost - v_penalty
        WHERE
            Hub_Region = v_hub_region
            AND Priority_Level = v_priority_level;

    END IF;

    -- ========================================================
    -- Add the NEW row's contribution if the new row is an
    -- SLA violation.
    -- ========================================================

    IF NEW.Delay_Minutes > 60 THEN

        SELECT
            h.Hub_Region,
            c.Customer_Priority_Level
        INTO
            v_hub_region,
            v_priority_level
        FROM Deliveries d
        JOIN Hubs h
            ON d.Hub_ID = h.Hub_ID
        JOIN Customers c
            ON d.Customer_ID = c.Customer_ID
        WHERE d.Delivery_ID = NEW.Delivery_ID;

        v_penalty := ROUND(((NEW.Delay_Minutes - 60) * 10.00)::NUMERIC, 2);

        INSERT INTO Fact_SLA_Region_Summary (
            Hub_Region,
            Priority_Level,
            Total_Violations,
            Total_Penalty_Cost
        )
        VALUES (
            v_hub_region,
            v_priority_level,
            1,
            v_penalty
        )
        ON CONFLICT (Hub_Region, Priority_Level)
        DO UPDATE SET
            Total_Violations = Fact_SLA_Region_Summary.Total_Violations + 1,
            Total_Penalty_Cost = Fact_SLA_Region_Summary.Total_Penalty_Cost + EXCLUDED.Total_Penalty_Cost;

    END IF;

    -- Remove empty summary rows if an update reduced a group to zero.
    DELETE FROM Fact_SLA_Region_Summary
    WHERE Total_Violations <= 0;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- Attach the trigger to Route_Logs.
-- It fires after inserts or updates.
-- ============================================================

DROP TRIGGER IF EXISTS trg_ivm_sla_update ON Route_Logs;

CREATE TRIGGER trg_ivm_sla_update
AFTER INSERT OR UPDATE ON Route_Logs
FOR EACH ROW
EXECUTE FUNCTION fn_ivm_sla_update();

-- ============================================================
-- Optional Test Code
-- Run this after creating the trigger to confirm the summary table
-- updates automatically.
-- ============================================================

-- Insert one new SLA-violating route log.
INSERT INTO Route_Logs (
    Route_ID,
    Delivery_ID,
    Vehicle_ID,
    Driver_ID,
    Weather_ID,
    Route_Distance,
    Delay_Minutes
)
VALUES (
    500001,
    1,
    1,
    1,
    1,
    100.00,
    75
);

-- Check the summary table after the insert.
SELECT *
FROM Fact_SLA_Region_Summary
ORDER BY
    Hub_Region,
    Priority_Level;

-- Update the same route to a larger delay.
UPDATE Route_Logs
SET Delay_Minutes = 120
WHERE Route_ID = 500001;

-- Check the summary table again.
SELECT *
FROM Fact_SLA_Region_Summary
ORDER BY
    Hub_Region,
    Priority_Level;