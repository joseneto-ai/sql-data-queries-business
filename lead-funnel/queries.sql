-- ============================================================
-- Lead Funnel Analysis Queries
-- ============================================================
-- Business context: measures lead volume, quality, and
-- distribution across the AI qualification pipeline.
--
-- Compatible with: PostgreSQL 14+ / MySQL 8+
-- Author: José Neto @zNeto.AI
-- ============================================================


-- ------------------------------------------------------------
-- 1. Weekly Lead Volume by Source
-- ------------------------------------------------------------
-- Shows how many leads arrived each week, grouped by source.
-- Use to identify which acquisition channels are growing
-- and which are underperforming.
-- ------------------------------------------------------------

SELECT
  DATE_TRUNC('week', created_at)  AS week_start,
  source,
  COUNT(*)                         AS total_leads
FROM leads
WHERE created_at >= NOW() - INTERVAL '90 days'
GROUP BY
  DATE_TRUNC('week', created_at),
  source
ORDER BY
  week_start DESC,
  total_leads DESC;

-- MySQL equivalent: replace DATE_TRUNC with:
-- DATE_FORMAT(created_at, '%Y-%u') AS week_start


-- ------------------------------------------------------------
-- 2. Lead Status Distribution (Current Snapshot)
-- ------------------------------------------------------------
-- Shows how leads are distributed across qualification
-- stages at this moment. Useful for daily operations review.
-- A large COLD bucket signals a nurture sequence is needed.
-- A large URGENT bucket signals a staffing alert.
-- ------------------------------------------------------------

SELECT
  status,
  COUNT(*)                                        AS total,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS percentage
FROM leads
GROUP BY status
ORDER BY total DESC;


-- ------------------------------------------------------------
-- 3. Average Intent Score by Source
-- ------------------------------------------------------------
-- Compares the average AI-assigned lead score per channel.
-- Higher scores = higher purchase intent.
-- Use to double down on channels bringing quality leads
-- and reduce investment in low-score channels.
-- ------------------------------------------------------------

SELECT
  source,
  COUNT(*)              AS total_leads,
  ROUND(AVG(score), 1)  AS avg_score,
  MIN(score)            AS min_score,
  MAX(score)            AS max_score
FROM leads
WHERE score IS NOT NULL
GROUP BY source
ORDER BY avg_score DESC;


-- ------------------------------------------------------------
-- 4. Funnel Drop-off Analysis
-- ------------------------------------------------------------
-- Tracks lead counts at each qualification stage.
-- The gap between HOT and APPOINTMENT_SCHEDULED reveals
-- where conversion friction exists.
-- ------------------------------------------------------------

SELECT
  'Total Leads'            AS stage,
  COUNT(*)                 AS count
FROM leads

UNION ALL

SELECT
  'HOT Leads'              AS stage,
  COUNT(*)
FROM leads
WHERE status = 'HOT'

UNION ALL

SELECT
  'Appointments Scheduled' AS stage,
  COUNT(*)
FROM appointments

UNION ALL

SELECT
  'Appointments Completed' AS stage,
  COUNT(*)
FROM appointments
WHERE status = 'completed'

ORDER BY count DESC;


-- ------------------------------------------------------------
-- 5. Off-Hours Lead Capture Rate
-- ------------------------------------------------------------
-- Measures leads that arrived outside business hours
-- (defined here as before 8:00 or after 18:00, Monday-Friday)
-- and the capture rate — showing the value of 24/7 automation.
-- Adjust the hour range to match your client's actual hours.
-- ------------------------------------------------------------

SELECT
  COUNT(*)                                           AS total_leads,

  SUM(
    CASE
      WHEN EXTRACT(HOUR FROM created_at) < 8
        OR EXTRACT(HOUR FROM created_at) >= 18
        OR EXTRACT(DOW  FROM created_at) IN (0, 6)
      THEN 1 ELSE 0
    END
  )                                                  AS off_hours_leads,

  ROUND(
    SUM(
      CASE
        WHEN EXTRACT(HOUR FROM created_at) < 8
          OR EXTRACT(HOUR FROM created_at) >= 18
          OR EXTRACT(DOW  FROM created_at) IN (0, 6)
        THEN 1 ELSE 0
      END
    ) * 100.0 / COUNT(*), 1
  )                                                  AS off_hours_percentage

FROM leads
WHERE created_at >= NOW() - INTERVAL '30 days';

-- MySQL equivalent: replace EXTRACT(DOW ...) with:
-- DAYOFWEEK(created_at) IN (1, 7)
-- and EXTRACT(HOUR ...) with HOUR(created_at)
