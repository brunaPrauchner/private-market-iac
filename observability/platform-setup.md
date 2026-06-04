# Observability Setup

The observability setup focuses on a small set of high-signal Datadog alerts that detect customer-impacting failures, transaction risk, and infrastructure degradation without creating excessive alert noise.

**Observability tool:** Datadog

## Setup

Datadog should collect telemetry across the main production layers:

- Infrastructure: AWS, EKS, Kubernetes nodes, pods, and load balancers
- Application: Elixir runtime, GraphQL API performance, errors, and logs
- Database: PostgreSQL on RDS health and availability
- Business workflows: transaction creation, transaction state transitions, failed jobs, and stuck workflows

## Tagging

Use consistent tags where the telemetry supports them:

- `env`
- `service`
- `component`
- `tier`

These tags make it easier to filter incidents by environment, service, platform component, or business criticality.

## Structured Logs

Application logs should be structured and include correlation fields:

- `request_id`
- `trace_id`
- GraphQL operation name
- Transaction or workflow ID, where safe
- Error reason or category

Logs should avoid sensitive data such as authentication tokens, personal information, financial details, and full GraphQL variables.

## Alerts 
Alerts should be designed around user impact and business risk.
I would divide alerting into two severities:
- **Critical:** Require immediate investigation because a core user or business function is broken, or production availability is severely threatened.
- **Warning:** non-urgent notifications or a ticket queue for investigation during business hours.

## Critical Alerts
Critical alerts should trigger only when a core business path is actively failing or production availability is at immediate risk.

### 1. Monthly Transaction SLO Error Budget Exhaustion
**Metric:** Core transaction success SLO error budget.

**Threshold:** Trigger when more than 75% of the 30-day error budget has been consumed.

**Why it matters:**  
For a low-frequency, high-value transaction platform, a large amount of consumed error budget can indicate reliability risk even when raw traffic volume is low. This alert highlights that the platform is approaching an unacceptable reliability position for critical transaction workflows.

### 2. External Synthetic Availability Check
**Metric:** Datadog API Synthetic test status.

**Threshold:** Trigger when the synthetic HTTP check fails from multiple locations.

**Why it matters:**  
The long-term goal is to validate important product flows such as login, market view loading, and a safe mock transaction. The current Terraform uses a simple GET request to an external portfolio site as a lightweight synthetic check so the alerting pipeline can be demonstrated and validated before a production-safe transaction test is available.

### 3. Database Primary Unavailability
**Metric:** RDS primary availability.

**Threshold:** Trigger when the primary database appears unreachable.

**Why it matters:**  
PostgreSQL on RDS is the source of truth for the platform. If the primary database is unavailable or unable to accept writes, core transaction workflows may fail immediately.

### 4. No Healthy Application Pods
**Metric:** Kubernetes deployment availability or ready pod count.

**Threshold:** Trigger when there are no healthy application pods available to serve production traffic.

**Why it matters:**  
If no application pods are healthy, users cannot reliably access the platform even if the database and other infrastructure are healthy. This is a direct availability incident and should page immediately.

### 5. Sustained GraphQL Operation Failures
**Metric:** GraphQL system error ratio grouped by operation name.

**Threshold:** Trigger when systemic GraphQL errors exceed 5% of traffic for an operation over a sustained window.

**Why it matters:**  
A single `/graphql` endpoint can hide which business workflow is failing, and GraphQL errors may appear inside successful HTTP responses. Monitoring individual GraphQL operations separately provides visibility into critical flows like login, market views, transaction updates, and admin workflows.

## Warning Alerts
Warning alerts should capture slow-burning regressions, early signs of capacity degradation, or anomalies. These require engineering attention during regular business hours to prevent them from changing into critical.

### 1. Slow Error Budget Burn
**Metric:** Monthly Error Budget Burn Rate.

**Threshold:** Trigger when error budget is being consumed faster than expected over a longer window (e.g. 24hours).

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