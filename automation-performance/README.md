# ⚙️ Automation Performance

Queries that measure how AI automation workflows are performing
operationally — response speed, throughput, escalation rates,
and agent coverage effectiveness.

Use these to answer questions like:
- What is the average response time of the AI agent?
- How many leads did the agent handle without human intervention?
- What percentage of interactions required escalation to staff?
- Is the agent maintaining sub-90-second response times?

---

## Queries in This Collection

### 1. Average Agent Response Time
Measures the mean, median, and 95th percentile of response
times across all automated interactions.

### 2. Daily Agent Throughput
Counts how many leads and interactions the AI agent handled
per day without requiring human intervention.

### 3. Escalation Rate by Day
Tracks what percentage of interactions triggered a human
escalation — a rising rate signals the agent needs retraining
or the system prompt needs updating.

### 4. Response Time SLA Compliance
Checks what percentage of responses met the target SLA
(under 90 seconds) over the reporting period.

### 5. Agent vs Human Interaction Split
Compares the volume of interactions handled autonomously
by the AI versus those that required human takeover.

---

## Files

- `README.md` — This documentation
- `queries.sql` — All queries with inline comments
