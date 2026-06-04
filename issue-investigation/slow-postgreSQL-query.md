# Issue: Slow PostgreSQL Query
A specific PostgreSQL query is performing slowly. The query is used to render a pricing chart that shows pricing information over time.
Here's the `EXPLAIN ANALYZE` output:
```
Hash Left Join (cost=126.50..148.74 rows=1008 width=44) (actual time=1.060..41.489 rows=858 loops=1)
Hash Cond: (c0.id = a3.company_id)

Join Filter: ((generate_series(('2022-01-01'::date)::timestamp with time zone, (date(timezone('America/New_York'::text, now())))::timestamp with time zone, '1 day'::interval)) = a3.price_day)

Rows Removed by Join Filter: 361371

-> Nested Loop (cost=90.87..110.47 rows=1000 width=56) (actual time=0.682..1.079 rows=858 loops=1)

-> Index Only Scan using companies_pkey on companies c0 (cost=0.28..4.30 rows=1 width=16) (actual time=0.012..0.013 rows=1 loops=1)

Index Cond: (id = '8d4c1967-391a-43dc-a231-d8e013f98ab5'::uuid)

Heap Fetches: 0

-> Merge Left Join (cost=90.59..96.17 rows=1000 width=40) (actual time=0.669..0.988 rows=858 loops=1)

Merge Cond: ((generate_series(('2022-01-01'::date)::timestamp with time zone, (date(timezone('America/New_York'::text, now())))::timestamp with time zone, '1 day'::interval)) = sp0.transaction_at)

-> Sort (cost=64.86..67.36 rows=1000 width=8) (actual time=0.573..0.635 rows=858 loops=1)

Sort Key: (generate_series(('2022-01-01'::date)::timestamp with time zone, (date(timezone('America/New_York'::text, now())))::timestamp with time zone, '1 day'::interval))

Sort Method: quicksort Memory: 65kB

-> ProjectSet (cost=0.00..5.03 rows=1000 width=8) (actual time=0.278..0.447 rows=858 loops=1)

-> Result (cost=0.00..0.01 rows=1 width=0) (actual time=0.001..0.001 rows=1 loops=1)

-> GroupAggregate (cost=25.73..25.87 rows=7 width=36) (actual time=0.092..0.144 rows=55 loops=1)

Group Key: sp0.transaction_at

-> Sort (cost=25.73..25.75 rows=7 width=8) (actual time=0.087..0.094 rows=59 loops=1)

Sort Key: sp0.transaction_at

Sort Method: quicksort Memory: 27kB

-> Bitmap Heap Scan on priced_transactions sp0 (cost=4.33..25.63 rows=7 width=8) (actual time=0.022..0.074 rows=59 loops=1)

Recheck Cond: (company_id = c0.id)

Heap Blocks: exact=45

-> Bitmap Index Scan on e1bbce45cf6637c020f7f1e176304403 (cost=0.00..4.33 rows=7 width=0) (actual time=0.010..0.010 rows=62 loops=1)

Index Cond: (company_id = c0.id)

-> Hash (cost=26.38..26.38 rows=740 width=24) (actual time=0.298..0.298 rows=739 loops=1)

Buckets: 1024 Batches: 1 Memory Usage: 49kB

-> Index Scan using "23b2c2d0cf8178b0df68aae6052dc300" on aggregate_price_graph a3 (cost=0.43..26.38 rows=740 width=24) (actual time=0.037..0.200 rows=739 loops=1)

Index Cond: (company_id = '8d4c1967-391a-43dc-a231-d8e013f98ab5'::uuid)

Planning Time: 0.813 ms

Execution Time: 41.610 ms
```
## Query Plan Analysis & Observations
While the current execution time is 41.6 ms, the query plan shows unnecessary join work that could become more expensive as the dataset grows.

### 1. Bottleneck: Massive Join Filtering
The primary performance bottleneck is
```text
Join Filter: ((generate_series(...)) = a3.price_day)
Rows Removed by Join Filter: 361371
```
This means PostgreSQL created a large number of candidate joined rows and then discarded most of them because they did not match the date join condition.


### 2. The Date Range Grows Over Time
The query generates dates from:
```text
2022-01-01
```
through the current date.

That means the generated date series grows every day. Even if the query is acceptable now, it can become slower over time as the date range and pricing dataset grow.

### 3. The Database May Be Doing Presentation Work
This pattern is used when rendering front-end charts 
over a timeline. If a private market stock has no trading 
activity on a given day, the database has no row for it. 
To prevent the React chart from skipping days and skewing 
the timeline, developers use `generate_series` to create 
empty rows for days with no activity, ensuring a smooth 
visual chart.

## Proposed Optimization Strategies
### Strategy A: Offload Timeline Filling to Elixir

PostgreSQL should return only pricing rows that actually exist, bounded by company and date range. The Elixir application can then fill missing days before returning the API response.

This keeps SQL simple and reduces unnecessary work on RDS.

### Strategy B: Keep Timeline Filling in SQL, but Refactor the Query

If the API must return a complete daily timeline directly from the database, I would keep timeline filling in SQL but refactor the query shape.

Move `generate_series()` into a clear CTE, pass explicit start and end dates, and join to `aggregate_price_graph` using both `company_id` and `price_day`.

This avoids the current plan where PostgreSQL joins too broadly and removes hundreds of thousands of rows afterward.

### Supporting Optimization: Add a Composite Index

For Strategy B, add a composite index:

```sql
CREATE INDEX CONCURRENTLY idx_aggregate_price_graph_company_id_price_day
ON aggregate_price_graph(company_id, price_day);
```
This index matches the lookup pattern for a company's pricing data over time and helps PostgreSQL join on both `company_id` and `price_day` efficiently.

### Supporting Optimization: Use a Bounded Date Range

The current query generates dates from `2022-01-01` to `now()`, which means the amount of work grows every day.

For a pricing chart, I would default to a bounded range such as `90D`, `6M`, or `1Y`, and only query longer historical ranges when the user explicitly requests them.

This reduces the number of generated dates, limits how many pricing rows need to be read, and keeps chart latency more predictable over time.

## Validation
To verify that the optimization successfully resolves the 
bottleneck, execute the following steps in staging environment:

1. **Verify the New Query Plan:** Run `EXPLAIN (ANALYZE, BUFFERS)` 
   on the refactored SQL query. Confirm that the 
   `Rows Removed by Join Filter` line drops.
2. **Audit Buffer Operations:** Verify that `shared hit` 
   buffer data page reads drop significantly, indicating 
   reduced disk and memory usage.
3. **Compare Execution Time:** Compare total execution time before and after changing the query.
4. **Monitor After Deployment:** Watch p95 and p99 latency, database CPU, IOPS, and query duration in Datadog after rollout.