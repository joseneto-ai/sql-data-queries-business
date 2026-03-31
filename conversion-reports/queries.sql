-- ============================================================
-- Conversion Report Queries
-- ============================================================
-- Business context: translates lead pipeline data into
-- measurable business outcomes and revenue indicators.
--
-- Compatible with: PostgreSQL 14+ / MySQL 8+
-- Author: José Neto @zNeto.AI
-- ============================================================


-- ------------------------------------------------------------
-- 1. Overall Conversion Rate (Lead to Appointment)
-- ------------------------------------------------------------
-- The single most important metric in the pipeline.
-- Measures what percentage of all leads end up scheduling
-- an appointment. Baseline target: 25-35% for healthcare.
-- ------------------------------------------------------------

SELECT
  COUNT(DISTINCT l.id)                               AS total_leads,
  COUNT(DISTINCT a.lead_id)                          AS total_appointments,
  ROUND(
    COUNT(DISTINCT a.lead_id) * 100.0
    / NULLIF(COUNT(DISTINCT l.id), 0), 1
  )                                                  AS conversion_rate_pct
FROM leads l
LEFT JOIN appointments a
  ON a.lead_id = l.id
WHERE l.created_at >= NOW() - INTERVAL '30 days';


-- ------------------------------------------------------------
-- 2. Conversion Rate by Lead Source
-- ------------------------------------------------------------
-- Breaks down conversion performance per acquisition channel.
-- Reveals which sources not only bring volume but also
-- convert — the two metrics often diverge significantly.
-- ------------------------------------------------------------

SELECT
  l.source,
  COUNT(DISTINCT l.id)                               AS total_leads,
  COUNT(DISTINCT a.lead_id)                          AS appointments,
  ROUND(
    COUNT(DISTINCT a.lead_id) * 100.0
    / NULLIF(COUNT(DISTINCT l.id), 0), 1
  )                                                  AS conversion_rate_pct,
  ROUND(AVG(l.score), 1)                             AS avg_lead_score
FROM leads l
LEFT JOIN appointments a
  ON a.lead_id = l.id
WHERE l.created_at >= NOW() - INTERVAL '30 days'
GROUP BY l.source
ORDER BY conversion_rate_pct DESC;


-- ------------------------------------------------------------
-- 3. Month-over-Month Pipeline Comparison
-- ------------------------------------------------------------
-- Compares current month to previous month across key metrics.
-- Use to track whether the automation is improving over time.
-- ------------------------------------------------------------

SELECT
  period,
  total_leads,
  hot_leads,
  appointments_scheduled,
  ROUND(
    appointments_scheduled * 100.0
    / NULLIF(total_leads, 0), 1
  )                             AS conversion_rate_pct
FROM (

  SELECT
    'Current Month'             AS period,
    COUNT(DISTINCT l.id)        AS total_leads,
    SUM(CASE WHEN l.status = 'HOT' THEN 1 ELSE 0 END)
                                AS hot_leads,
    COUNT(DISTINCT a.id)        AS appointments_scheduled
  FROM leads l
  LEFT JOIN appointments a ON a.lead_id = l.id
  WHERE l.created_at >= DATE_TRUNC('month', NOW())

  UNION ALL

  SELECT
    'Previous Month'            AS period,
    COUNT(DISTINCT l.id)        AS total_leads,
    SUM(CASE WHEN l.status = 'HOT' THEN 1 ELSE 0 END)
                                AS hot_leads,
    COUNT(DISTINCT a.id)        AS appointments_scheduled
  FROM leads l
  LEFT JOIN appointments a ON a.lead_id = l.id
  WHERE
    l.created_at >= DATE_TRUNC('month', NOW()) - INTERVAL '1 month'
    AND l.created_at <  DATE_TRUNC('month', NOW())

) AS period_comparison;

-- MySQL equivalent: replace DATE_TRUNC with
-- DATE_FORMAT(NOW(), '%Y-%m-01') for month start


-- ------------------------------------------------------------
-- 4. HOT Lead Conversion Rate
-- ------------------------------------------------------------
-- Tracks specifically how HOT leads (score 8+) are converting.
-- If the AI classifies a lead as HOT but it doesn't convert,
-- the triage logic or follow-up process needs review.
-- ------------------------------------------------------------

SELECT
  COUNT(DISTINCT l.id)                               AS hot_leads,
  COUNT(DISTINCT a.lead_id)                          AS hot_leads_converted,
  ROUND(
    COUNT(DISTINCT a.lead_id) * 100.0
    / NULLIF(COUNT(DISTINCT l.id), 0), 1
  )                                                  AS hot_conversion_rate_pct
FROM leads l
LEFT JOIN appointments a
  ON a.lead_id = l.id
WHERE
  l.status      = 'HOT'
  AND l.score   >= 8
  AND l.created_at >= NOW() - INTERVAL '30 days';


-- ------------------------------------------------------------
-- 5. Revenue Impact Estimate
-- ------------------------------------------------------------
-- Estimates the revenue value generated specifically by
-- off-hours lead capture — leads that would have been lost
-- without 24/7 automation.
--
-- Adjust avg_ticket_value to match the client's actual
-- average procedure or service value.
-- ------------------------------------------------------------

WITH off_hours_leads AS (
  SELECT
    l.id,
    l.status,
    a.id AS appointment_id
  FROM leads l
  LEFT JOIN appointments a ON a.lead_id = l.id
  WHERE
    l.created_at >= NOW() - INTERVAL '30 days'
    AND (
      EXTRACT(HOUR FROM l.created_at) < 8
      OR EXTRACT(HOUR FROM l.created_at) >= 18
      OR EXTRACT(DOW  FROM l.created_at) IN (0, 6)
    )
),
summary AS (
  SELECT
    COUNT(DISTINCT id)              AS off_hours_leads_captured,
    COUNT(DISTINCT appointment_id)  AS off_hours_appointments
  FROM off_hours_leads
)
SELECT
  off_hours_leads_captured,
  off_hours_appointments,

  -- Adjust this value to the client's average ticket
  3500                              AS avg_ticket_value_brl,

  off_hours_appointments * 3500     AS estimated_revenue_recovered_brl,

  ROUND(
    off_hours_appointments * 100.0
    / NULLIF(off_hours_leads_captured, 0), 1
  )                                 AS off_hours_conversion_rate_pct

FROM summary;

-- To adapt: replace 3500 with the client's actual
-- average procedure value in their local currency.
