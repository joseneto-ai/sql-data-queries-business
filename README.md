# 🗄️ SQL Data Queries — Business Intelligence

A curated collection of business-focused SQL queries built for
analyzing the output of AI automation workflows — lead pipelines,
operational performance, and conversion metrics.

Each query is documented with business context, expected output,
and notes on how to adapt it to your own schema. Compatible with
PostgreSQL and MySQL.

These queries are used internally at zNeto.AI to measure the
performance of automation systems delivered to clients.

---

## 📁 Query Collections

### 1. 🔽 Lead Funnel Analysis
Queries that track leads across every stage of the qualification
pipeline — volume, drop-off points, source performance, and
intent score distribution.

→ [`/lead-funnel`](./lead-funnel/README.md)

---

### 2. ⚙️ Automation Performance
Queries that measure how AI automation workflows are performing —
response times, agent throughput, escalation rates, and
off-hours coverage effectiveness.

→ [`/automation-performance`](./automation-performance/README.md)

---

### 3. 📈 Conversion Reports
Queries that translate lead pipeline data into business outcomes —
conversion rates, revenue attribution, period-over-period
comparisons, and ROI indicators.

→ [`/conversion-reports`](./conversion-reports/README.md)

---

## 🛠️ Compatibility

All queries are written in standard SQL and tested against:
- **PostgreSQL 14+**
- **MySQL 8+**

Minor syntax differences are noted inline where they exist.

---

## 🗂️ Schema Reference

All queries assume the following core tables. Adapt column
names to match your own database schema.
```sql
-- leads table
CREATE TABLE leads (
  id            VARCHAR(50)  PRIMARY KEY,
  name          VARCHAR(100) NOT NULL,
  status        VARCHAR(20)  NOT NULL,  -- HOT, WARM, COLD, URGENT
  score         INTEGER,                -- 1 to 10
  source        VARCHAR(50),            -- WhatsApp, Web Form, etc.
  created_at    TIMESTAMP    NOT NULL,
  updated_at    TIMESTAMP    NOT NULL
);

-- interactions table
CREATE TABLE interactions (
  id            VARCHAR(50)  PRIMARY KEY,
  lead_id       VARCHAR(50)  REFERENCES leads(id),
  channel       VARCHAR(50),            -- whatsapp, email, web
  message_text  TEXT,
  direction     VARCHAR(10),            -- inbound, outbound
  created_at    TIMESTAMP    NOT NULL
);

-- automation_events table
CREATE TABLE automation_events (
  id            VARCHAR(50)  PRIMARY KEY,
  event_type    VARCHAR(50)  NOT NULL,  -- lead_qualified, escalated, etc.
  lead_id       VARCHAR(50)  REFERENCES leads(id),
  agent_id      VARCHAR(50),
  response_time INTEGER,                -- seconds
  created_at    TIMESTAMP    NOT NULL
);

-- appointments table
CREATE TABLE appointments (
  id            VARCHAR(50)  PRIMARY KEY,
  lead_id       VARCHAR(50)  REFERENCES leads(id),
  scheduled_at  TIMESTAMP    NOT NULL,
  status        VARCHAR(20),            -- confirmed, cancelled, completed
  created_at    TIMESTAMP    NOT NULL
);
```

---

## 👤 Author

**José Neto** — AI Automation Engineer & Founder @zNeto.AI

[![LinkedIn](https://img.shields.io/badge/LinkedIn-José%20Neto-0077B5?style=flat&logo=linkedin)](https://www.linkedin.com/in/jos%C3%A9-neto-b88558398)
[![GitHub](https://img.shields.io/badge/GitHub-joseneto--ai-181717?style=flat&logo=github)](https://github.com/joseneto-ai)
