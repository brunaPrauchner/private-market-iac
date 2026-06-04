# Observability Setup

The observability setup should focus on a small set of high-signal telemetry that quickly detects customer-impacting failures, transaction risk, and infrastructure degradation without creating excessive alert noise.

**Observability tool:** Datadog

## Setup
Datadog should be configured to collect telemetry across the main production layers:
- Infrastructure: AWS, EKS, Kubernetes nodes, pods, and load balancers
- Application: Elixir runtime, GraphQL API performance, errors, and logs
- Database: PostgreSQL on RDS health, latency, saturation, and backup status
- Business workflows: transaction creation, transaction state transitions, failed jobs, and stuck workflows

## Tagging
Use consistent tags everywhere:
- `env`
- `service`
- `version`
- `team`
- `cluster`
- `namespace`
- `region`

Consistent tags make it easier to filter incidents by environment, deployment version, service, namespace, or region.

## Structured Logs
Application logs should be structured and include correlation fields:

- `request_id`
- `trace_id`
- `user_id` or account identifier, where safe
- GraphQL operation name
- Transaction or workflow ID, where safe
- Error reason or category

Logs should avoid sensitive data such as authentication tokens, personal information, financial details, and full GraphQL variables.

## Alerts 
Alerts should be designed around user impact and business risk.
I would divide alerting into two severities:
- **Critical:** Require immediate investigation because a core user or business function is broken, or production availability is severely threatened.
- **Warning:** non-urgent notifications or a ticket queue for investigation during business hours.

## 🚨 Critical Alerts
Critical alerts should trigger only when a core business path is actively failing or production availability is at immediate risk.

### 1. Multi-Window, Multi-Burn-Rate SLO Alert
**Metric:** Core transaction success rate (SLI).

**Threshold:** Trigger when a meaningful portion of the monthly transaction error budget is consumed in a short window, such as 2% within 1 hour.

**Why it matters:**  
A static error-rate threshold may not work well for a low-volume platform. While a single intermittent network glitch shouldn't page an engineer, repeated transaction failures or a sustained burn of our error budget in a short period indicates an issue that requires immediate incident response.

A burn-rate alert detects the pace of reliability degradation and helps the team respond before more material transactions are impacted.

### 2. End-to-End Synthetic Transaction Failure
**Metric:** Datadog Browser or API Synthetic test status.

**Threshold:** Trigger when the end-to-end synthetic test fails consecutively from multiple locations or multiple test runs.

**Why it matters:**  
Because the platform is low frequency, there may be long periods with little or no real user traffic. Passive dashboards can look healthy simply because no one is using the system.

Synthetic tests proactively verify that critical flows still work, such as logging in, loading a private market view, and submitting a safe test transaction flow. This helps detect silent failures before a real high-value user is affected.

### 3. Database Primary Unavailability or Storage Exhaustion
**Metric:** RDS availability, failover state, connection health, and free storage space.

**Threshold:** Trigger when the primary database is unreachable for more than 3 minutes (indicating an automated Multi-AZ failover has hung or failed), or when available storage drops below 10%.

**Why it matters:**  
PostgreSQL on RDS is the source of truth for the platform. If the database is unavailable, out of storage, or unable to accept writes, core transaction workflows may fail immediately.

### 4. No Healthy Application Pods
**Metric:** Kubernetes deployment availability, ready pod count, and load balancer target health.

**Threshold:** Trigger when there are no healthy application pods available to serve production traffic.

**Why it matters:**  
If no application pods are healthy, users cannot reliably access the platform even if the database and other infrastructure are healthy. This is a direct availability incident and should page immediately.

### 5. Sustained 5xx or GraphQL Operation Failures
**Metric:** HTTP 5xx error rate and GraphQL error metrics grouped by operation name.

**Threshold:** Trigger when backend errors remain above the agreed SLO threshold for a sustained period.

**Why it matters:**  
A single `/graphql` endpoint can hide which business workflow is failing, and GraphQL errors may appear inside successful HTTP responses. Monitoring individual GraphQL operations separately provides visibility into critical flows like login, market views, bid submissions, transaction updates, and admin workflows.

### 6. Stuck or Failing Transaction Workflows
**Metric:** Transaction state transitions, failed workflow count, and transaction-critical background job status.

**Threshold:** Trigger when transactions remain in an intermediate state longer than expected, or when transaction-critical background jobs stop processing.

**Why it matters:**  
Infrastructure can look healthy while a business workflow is broken. For a high-value transaction platform, stuck or failed transaction workflows are critical because they may require immediate intervention to protect correctness and client trust.


## ⚠️ Warning Alerts
Warning alerts should capture slow-burning regressions, early signs of capacity degradation, or anomalies. These require engineering attention during regular business hours to prevent them from changing into critical.

### 1. Slow Error Budget Burn
**Metric:** Monthly Error Budget Burn Rate.

**Threshold:** Trigger when error budget is being consumed faster than expected over a longer window.

**Why it matters:**  
A slow burn may not represent an active outage, but it shows that reliability is trending in the wrong direction and should be reviewed before it threatens our monthly availability target.

### 2. Silent Platform Inactivity During Business Hours
**Metric:** Request rate and core business event rate.

**Threshold:** Trigger when there are zero requests or zero expected business events over a defined window during normal business hours.

**Why it matters:**  
Because the platform is low frequency, zero traffic may be normal outside business hours. During expected usage windows, however, complete inactivity can indicate an upstream routing issue, broken frontend, authentication problem, DNS issue, or telemetry gap.

### 3. Progressive Resource Depletion (EKS Nodes & Pods)
**Metric:** Kubernetes cluster node CPU/Memory allocation and HPA (Horizontal Pod Autoscaler) limits.

**Threshold:** Trigger when workloads are consistently near resource limits or pods are having scheduling issues.

**Why it matters:**  
Sustained Kubernetes resource pressure can lead to slow requests, failed scheduling, restarts, or reduced availability during traffic spikes.

### 4. External Dependency Degradation
**Metric:** Third-party API latency, error rate, and timeout rate.

**Threshold:** Latency or error rates exceed the p95 historical baseline for more than 10 minutes.

**Why it matters:**  
External dependency issues can become business-impacting depending on whether the dependency is in the critical transaction path. Warning alerts allow the team to monitor the situation and prepare mitigation.

### 5. Automated Backup or Maintenance Sync Failures
**Metric:** RDS automated backup status, latest restorable time, backup retention period, and scheduled maintenance/data sync job status.

**Threshold:** Any scheduled database backup or critical background data sync job fails or skips a scheduled window.

**Why it matters:**  
A missed backup does not impact immediate system uptime, but it increases recovery risk if a disaster recovery event occurs before it is fixed.

### 6. Increasing GraphQL Latency
**Metric:** p95 and p99 latency for GraphQL operations.

**Threshold:** Trigger when latency for important operations is above the normal baseline for a sustained period.

**Why it matters:**  
Increasing latency can be an early signal of database pressure, inefficient queries, dependency slowness, or application performance regression.

### 7. RDS Resource Pressure
**Metric:** RDS CPU, memory, connections, IOPS, and storage trends.

**Threshold:** Trigger when resource usage is trending toward unsafe levels but has not yet reached a critical threshold.

**Why it matters:**  
Database pressure often appears before a full outage. Warning alerts give the team time to investigate capacity, query behavior, and connection pool usage before users are affected.

#### Proactive Monitoring for Low-Frequency Volume
Because the platform is low frequency, there may be long periods with little or no real transaction activity. In that environment, passive dashboards can look healthy simply because no users are exercising the system.

To catch silent failures, I would configure Datadog Synthetic tests to run on a regular schedule. These tests should validate the most important user and API paths, such as logging in, loading a private market view, and submitting a safe mock or test transaction flow.

This gives the team confidence that core workflows are still functioning even when production traffic is quiet, and it helps detect issues before a real high-value transaction is affected.

## Dashboards
Dashboards should have a clear audience and purpose.
I would create a small number of focused dashboards:

#### High-Level Business Health Dashboard

**Audience:** Leadership, product owners, and managers.

**Intent:** Show whether the platform is meeting its business promises and whether reliability is trending in the right direction.

**What to include:**

- SLO status and remaining error budget
- Platform availability
- Successful transaction count
- Failed transaction count
- Total transaction value processed, if safe to expose or percentage volume trend relative to the historical baseline 
- Active users or active sessions
- Major incident count over time
- High-level latency and error rate trends

#### Triage Dashboard

**Audience:** On-call engineers responding to an active alert.

**Intent:** Answer within 30 seconds: is the system broken right now, how badly, and where should I look first?

**What to include:**
- The four golden signals:
    - Latency by percentile: p50, p95, and p99
    - Traffic: HTTP request rate, GraphQL request rate, and transaction volume
    - Errors: HTTP 5xx rate, GraphQL error rate, and failed database connections
    - Saturation: CPU, memory, connection pools, disk I/O

#### Downstream Infrastructure Dashboard

**Audience:** Engineers who have identified a symptom on the triage dashboard and need to isolate the likely cause.

**Intent:** Provide a root-cause view of the technical dependencies that support the application.

**What to include:**

- Database health: active connections, connection pool usage, read/write IOPS, query latency, slow queries, lock waits, deadlocks
- Load balancer health: request count, target health, 4xx/5xx responses, latency
- Network health: cross-Availability Zone traffic, packet drops, DNS failures, and network error rates
- External dependencies: latency, error rates, and timeout rates for third-party APIs such as payment providers, KYC services, market data providers, or email services
- AWS service dependencies: health and error rates for services the platform depends on, such as S3, SQS, SNS

Dependencies should be grouped based on whether they are in the critical path of a transaction. For example, an email provider outage may be non-critical if transactions can still process, while a payment provider outage may block core business workflows. Classifying dependencies this way helps the engineer quickly understand and prioritize the response.

#### Continuous Delivery & Change Dashboard

**Audience:** Developers, SREs, and release owners reviewing deployments.

**Intent:** Correlate system health with recent application, infrastructure, or configuration changes.

**What to include:**

- Deployment markers overlaid on error rate, latency, and traffic graphs
- Terraform apply markers for infrastructure changes
- Current and previous application versions
- Error rate and latency before and after deployment
- Pod restarts or rollout failures after deployment
