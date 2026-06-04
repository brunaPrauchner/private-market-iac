# Issue: Elevated Error Rates
After a recent deployment, the platform started returning elevated 500 errors. The deployment introduced a new feature that queries a new database table.

The logs showed:
```
Elixir.DBConnection.ConnectionError: connection not available and request was dropped from queue after 219ms. This means requests are coming in and your connection pool cannot serve them fast enough. You can address this by:
 1. Ensuring your database is available and that you can connect to it
 2. Tracking down slow queries and making sure they are running fast enough
 3. Increasing the pool_size (although this increases resource consumption)
 4. Allowing requests to wait longer by increasing :queue_target and :queue_interval;
```

## Investigation Steps
### Step 1: Mitigate the Incident & Stabilize Production
I would establish the incident timeline and impact
1. **Confirm Scope and Timeline via Custom Dashboards:** 

* **Continuous Delivery & Change Dashboard:** Correlate the exact timestamp of the 500 error spikes with our automated deployment markers.
* **Triage Dashboard:** Check percentiles (p95/p99) 
     to isolate which specific GraphQL operations are 
     failing and audit the connection pool wait times.
* **Downstream Infrastructure Dashboard:** Cross-reference 
     RDS infrastructure metrics (CPU, memory, connection 
     counts, IOPS, and query latency).

2. **Restore System Availability:**

* **Option 1 (Feature Flag):** Disable the 
     deployed feature immediately behind a 
     feature flag, if available.
* **Option 2 (Rollback):** If a flag is unavailable, 
     execute an immediate rollback to the previous 
     stable application version (ensuring the deployment 
     did not include destructive schema changes).
* **Option 3 (Pool Adjustments):** If a rollback is not possible, apply a temporary configuration patch to increase the `:pool_size` or extend the `:queue_target` and `:queue_interval`. It may reduce dropped requests temporarily, but it can also increase pressure on RDS, so I would use it only as a short-term mitigation while investigating the underlying query issue.

### Step 2: Investigate in Datadog
Next, I would use Datadog to isolate the failing path

Specific steps:
* **Filter APM Traces:** Navigate to **APM -> Traces**, 
  select the Elixir monolith service, and filter strictly 
  for HTTP `500` status codes.
* **Isolate the GraphQL Operation:** Identify which 
  specific GraphQL operation names are associated 
  with the `DBConnection.ConnectionError`.
* **Inspect the Trace Flame Graph:** Click into a failing 
  trace and inspect its layout. Look for an elongated database query span that is immediately followed by an application connection timeout exception.


### Step 3: Deep Dive into the PostgreSQL
After identifying the likely failing operation, I would inspect PostgreSQL directly.

* **Run targeted pg_stat_activity:** Run a targeted query against `pg_stat_activity` to find queries waiting on locks:
    ```sql
   SELECT pid, age(clock_timestamp(), query_start), usename, query, state 
   FROM pg_stat_activity 
   WHERE wait_event_type = 'Lock' 
   ORDER BY age DESC;
    ```
* **Analyze the Query Execution Plan:** Take the SQL query discovered in APM and execute it with `EXPLAIN` to read how the database processes it:
   ```sql
   EXPLAIN (ANALYZE, BUFFERS) 
   SELECT * FROM new_table 
   WHERE new_column = 'XYZ';
   ```
If it shows a sequential scan with high cost and long execution time, I would suspect a missing or incorrect index.

If the trace shows many repeated queries for a single GraphQL request, I would suspect an N+1 query issue.

## Likely Root Cause
My leading hypothesis would be that the new feature introduced a slow query against the new table, likely due to one of these causes:

- Missing index
- Inefficient join
- Unbounded result set
- Missing pagination
- GraphQL N+1 query pattern

Slow queries hold database connections longer. As requests pile up, the connection pool queue fills, and DBConnection starts dropping requests after the queue timeout. That explains why a database query regression can appear externally as elevated 500 errors.

### Step 4: Resolution
### If the Issue Is a Missing Index
Write a database migration script to apply a concurrent index to the target columns:

```sql
CREATE INDEX CONCURRENTLY idx_new_table_column
ON new_table(new_column);
```

* Using CONCURRENTLY ensures Postgres builds the index without locking the table, preventing further downtime on the live platform.
### If the Issue Is an N+1 Query
Work with the developers to refactor the database call.
- Using `Repo.preload`
- proper GraphQL dataloader (like Absinthe's Dataloader)

The goal is to turn many small database queries into one predictable query or a small number of batched queries.

#### How to Test the Fix
I would test the fix before and after deployment:

- Confirm the updated query uses the expected index with `EXPLAIN (ANALYZE, BUFFERS)`. Verify that the query plan 
   output has successfully changed from a high-cost 
   `Seq Scan` to an optimized `Index Scan` or 
   `Bitmap Index Scan`. Ensure execution times and 
   buffer reads decrease significantly.
- Run a load test against the affected endpoint or GraphQL operation.
- If the fix involved application refactoring, trace a single mock 
   request inside Datadog APM within the staging environment. Confirm that the Trace Flame Graph no longer shows a cascading waterfall of hundreds of repetitive, sequential database spans, but rather a single batched database call.

### Step 5: Long-Term Prevention
To prevent similar database connection pool starvation in future deployments, I would add:
* **Query and Schema Review:** Add lightweight CI and code review checks for database-impacting changes. New tables, foreign keys, join columns, and heavily queried lookup fields should be reviewed for appropriate indexes before merge. For high-risk queries, include `EXPLAIN (ANALYZE, BUFFERS)` output in the pull request to confirm the expected query plan.
* **Realistic Load Testing in Staging:** Ensure the 
  staging database environment contains a realistic, 
  production-scale dataset size.