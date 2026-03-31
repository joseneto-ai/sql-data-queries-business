-- ============================================================
-- Automation Performance Queries
-- ============================================================
-- Business context: measures AI agent operational efficiency,
-- response speed, throughput, and escalation behavior.
--
-- Compatible with: PostgreSQL 14+ / MySQL 8+
-- Author: José Neto @zNeto.AI
-- ============================================================


-- ------------------------------------------------------------
-- 1. Average Agent Response Time
-- ------------------------------------------------------------
-- Measures response time statistics across all automated
-- interactions. The 95th percentile reveals worst-case
-- performance that average metrics would hide.
-- Target: avg under 90 seconds, p95 under 300 seconds.
-- ------------------------------------------------------------

SELECT
  COUNT(*)                                         AS total_events,
  ROUND(AVG(response_time), 0)                     AS avg_response_seconds,
  PERCENTILE_CONT(0.5)
    WITHIN GROUP (ORDER BY response_time)          AS median_response_seconds,
  PERCENTILE_CONT(0.95)
    WITHIN GROUP (ORDER BY response_time)          AS p95_response_seconds,
  MIN(response_time)                               AS min_response_seconds,
  MAX(response_time)                               AS max_response_seconds
FROM automation_events
WHERE
  event_type    = 'agent_response'
  AND created_at >= NOW() - INTERVAL '30 days';

-- MySQL: replace PERCENTILE_CONT with a subquery approach
-- as MySQL does not natively support ordered-set aggregates.


-- ------------------------------------------------------------
-- 2. Daily Agent Throughput
-- ------------------------------------------------------------
-- Counts how many interactions the AI agent handled each day.
-- Use to identify volume spikes, quiet periods, and growth
-- trends in automated interaction volume.
-- ------------------------------------------------------------

SELECT
  DATE(created_at)   AS interaction_date,
  COUNT(*)           AS total_interactions,
  COUNT(DISTINCT lead_id) AS unique_leads_handled
FROM automation_events
WHERE
  event_type     = 'agent_response'
  AND created_at >= NOW() - INTERVAL '30 days'
GROUP BY DATE(created_at)
ORDER BY interaction_date DESC;


-- ------------------------------------------------------------
-- 3. Escalation Rate by Day
-- ------------------------------------------------------------
-- Tracks the daily percentage of interactions that triggered
-- a human escalation. A consistently rising rate signals that
-- the AI agent is encountering edge cases it cannot handle —
-- a system prompt update or retraining may be needed.
-- ------------------------------------------------------------

SELECT
  DATE(created_at)                                   AS event_date,

  COUNT(*)                                           AS total_events,

  SUM(CASE WHEN event_type = 'escalated' THEN 1 ELSE 0 END)
                                                     AS escalations,

  ROUND(
    SUM(CASE WHEN event_type = 'escalated' THEN 1 ELSE 0 END)
    * 100.0 / COUNT(*), 1
  )                                                  AS escalation_rate_pct

FROM automation_events
WHERE created_at >= NOW() - INTERVAL '30 days'
GROUP BY DATE(created_at)
ORDER BY event_date DESC;


-- ------------------------------------------------------------
-- 4. Response Time SLA Compliance
-- ------------------------------------------------------------
-- Measures the percentage of responses that met a defined
-- SLA threshold (default: 90 seconds).
-- Adjust the threshold value to match the client SLA.
-- ------------------------------------------------------------

WITH response_data AS (
  SELECT
    response_time,
    CASE WHEN response_time <= 90 THEN 1 ELSE 0 END AS met_sla
  FROM automation_events
  WHERE
    event_type    = 'agent_response'
    AND created_at >= NOW() - INTERVAL '30 days'
    AND response_time IS NOT NULL
)
SELECT
  COUNT(*)                                      AS total_responses,
  SUM(met_sla)                                  AS responses_within_sla,
  COUNT(*) - SUM(met_sla)                       AS responses_breached_sla,
  ROUND(SUM(met_sla) * 100.0 / COUNT(*), 1)    AS sla_compliance_pct
FROM response_data;


-- ------------------------------------------------------------
-- 5. Agent vs Human Interaction Split
-- ------------------------------------------------------------
-- Compares how much of the total interaction volume was
-- handled autonomously by the AI versus handed to a human.
-- The goal is to maximize AI_HANDLED percentage over time.
-- ------------------------------------------------------------

SELECT
  CASE
    WHEN event_type IN ('agent_response', 'automated_follow_up')
      THEN 'AI_HANDLED'
    WHEN event_type IN ('escalated', 'human_response')
      THEN 'HUMAN_HANDLED'
    ELSE 'OTHER'
  END                                                        AS handler_type,

  COUNT(*)                                                   AS total,

  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1)        AS percentage

FROM automation_events
WHERE created_at >= NOW() - INTERVAL '30 days'
GROUP BY handler_type
ORDER BY total DESC;
