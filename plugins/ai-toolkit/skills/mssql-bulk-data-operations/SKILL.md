---
name: mssql-bulk-data-operations
description: Generates production-ready batched T-SQL scripts for large-scale UPDATE and DELETE operations on MSSQL, plus tracking-table staging for batch processing, with progress tracking, checkpointing, and transaction safety. Use for bulk or mass data operations, batch updates/deletes, or changing millions of records.
type: guidance
applies_to:
  - Developer
  - DBA
mandatory: conditional
mandatory_when:
  - Performing large-scale UPDATE or DELETE operations (millions of rows)
  - Staging record IDs into a tracking table for batch processing
triggers:
  - bulk update
  - bulk insert
  - bulk delete
  - update large dataset
  - update millions of records
  - batch update
  - batch insert
  - large data operation
  - update 3M records
  - mass update
references:
  - templates/batch-insert.sql
  - templates/batch-update.sql
summary: Generates production-ready batched T-SQL for large-scale UPDATE/DELETE on MSSQL, plus tracking-table staging, with progress tracking, checkpointing, and transaction safety.
---

# Bulk Data Operations

## Purpose
Generates production-ready T-SQL scripts for processing large datasets (millions of rows) in safe, resumable batches with real-time progress reporting.

## When to Use
Use this when the user asks to:
- Update or delete a large number of records (typically millions), or stage record IDs into a tracking table for batch processing
- Perform a bulk data operation that needs batching to avoid lock escalation
- Generate a safe batch processing script for a large table

## Role
You are a Senior Database Engineer specializing in large-scale MSSQL data operations.

## Operating Modes

### Mode 1: BULK INSERT (Populate Tracking Table)
**Triggers:** "add N records", "insert N rows", "populate tracking table"
**Output:** A script that batch-inserts IDs from a source table into a `BulkProcessTracking` tracking table.

### Mode 2: BULK UPDATE
**Triggers:** "update N records", "modify N rows", "batch update"
**Output:** Two scripts:
1. **Tracking Insert Script** — populates the tracking table with target IDs
2. **Update Script** — processes the tracked IDs in batches, applying the requested changes

### Mode 3: BULK DELETE
**Triggers:** "delete N records", "remove N rows", "purge old data"
**Output:** Two scripts:
1. **Tracking Insert Script** — populates the tracking table with target IDs
2. **Delete Script** — deletes tracked rows in batches (adapted from the update template)

## Process

### Step 1: Gather Requirements
Ask the user (if not already provided):
- **Target table** — Schema and table name (e.g., `dbo.Orders`)
- **Operation** — INSERT, UPDATE, or DELETE
- **Filter/WHERE clause** — Which records to target (e.g., `WHERE Status = 'Inactive'`, `WHERE CreatedAt < '2024-01-01'`)
- **Update columns** (for UPDATE mode) — What columns to change and to what values
- **Estimated row count** — To confirm batching is appropriate (use this to set expectations on runtime)
- **ID column name** — The primary key or identity column to batch on; resolve it from the target schema when the user does not supply it
- **ID column type** — This template supports only integral `INT` or `BIGINT` keys. For any other key type, design and review a type-safe keyset implementation instead of adapting this arithmetic/key-order template.

#### Canonical Placeholder Vocabulary

Use brace tokens only. They are scaffold-time placeholders: resolve each token before returning executable SQL. The tracking tables reuse `{KeyColumn}` rather than introducing a second key-column alias.

| Token | Meaning |
|---|---|
| `{Schema}` | Target table schema |
| `{TableName}` | Target table name |
| `{KeyColumn}` | Target primary-key or identity column, reused as the tracking-table key |
| `{KeyType}` | Integral SQL data type of `{KeyColumn}`; only `INT` or `BIGINT` is supported by these templates |
| `{FilterPredicate}` | Required predicate body, without the `WHERE` keyword, qualified with the `mt` source alias; use `1 = 1` only when the user explicitly targets every source row |
| `{yyyyMMddHHmm}` | 12-digit UTC scaffold-time value, such as `202603171430`, shared by the tracker and in-progress table names for the operation |
| `{UpdateExpression}` | Complete comma-separated assignment list after `SET`, qualified with the `mt` alias |
| `{IndexName}` | Actual nonclustered index name when optional disable/rebuild advice is emitted |

### Step 2: Generate Tracking Table Setup
Always output the schema + table creation block first (uncommented, ready to run):

```sql
-- ============================================
-- SETUP: Create tracking infrastructure
-- Run this ONCE before the batch scripts
-- ============================================

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'BulkProcessTracking')
BEGIN
    CREATE SCHEMA [BulkProcessTracking];
END
GO

CREATE TABLE [BulkProcessTracking].[{yyyyMMddHHmm}_Tracker]
(
    [{KeyColumn}] {KeyType} PRIMARY KEY,
    IsProcessed BIT NOT NULL DEFAULT 0
);

CREATE NONCLUSTERED INDEX IDX_IsProcessed
ON [BulkProcessTracking].[{yyyyMMddHHmm}_Tracker](IsProcessed)
INCLUDE ([{KeyColumn}]);
GO
```

Resolve `{yyyyMMddHHmm}` once for the operation and reuse it in every script. Resolve `{KeyType}` to the actual key-column type.

For UPDATE/DELETE operations, also create the in-progress table:

```sql
CREATE TABLE [BulkProcessTracking].[{yyyyMMddHHmm}_InProgress]
(
    [{KeyColumn}] {KeyType} PRIMARY KEY
);
GO
```

### Step 3: Generate Batch Scripts
Use the templates from `templates/batch-insert.sql` and `templates/batch-update.sql` as the foundation.

#### Resolve Template Tokens

Resolve the canonical tokens above throughout both templates. `{UpdateExpression}` is required only for UPDATE mode; DELETE mode replaces the UPDATE statement as described below. Do not leave brace tokens or invent alternate aliases in executable output.

`{FilterPredicate}` is never optional. Apply the same resolved predicate to the source-key `MIN`, source-key `MAX`, eligible-row `COUNT_BIG`, and batched source selection. This keeps bounds, progress, and selected rows on one target set. The insert template advances with a strict `>` keyset cursor and never computes `MAX(key) + 1`, so `BIGINT` maximum values remain safe.

#### Batch Size Guidance
| Record Count | Recommended @BatchSize |
|--------------|----------------------|
| < 100K | 2,500 - 4,500 |
| 100K - 1M | 2,000 - 4,500 |
| 1M - 10M | 1,000 - 4,500 |
| > 10M | 500 - 2,500 |

Factors that reduce batch size: wide tables, many indexes, heavy concurrent load, Azure SQL DTU limits.

#### For DELETE operations
Adapt the update template by replacing the UPDATE statement with DELETE:

```sql
-- Delete rows using the selected batch of IDs
DELETE mt
FROM [{Schema}].[{TableName}] AS mt WITH (ROWLOCK)
INNER JOIN [BulkProcessTracking].[{yyyyMMddHHmm}_InProgress] AS ttip ON ttip.[{KeyColumn}] = mt.[{KeyColumn}];
```

Keep the surrounding claim and transaction logic unchanged. The shared in-progress table is truncated inside the same transaction, immediately before tracker claims are written to it, so concurrent or resumed executors cannot interleave the reset with another batch's claim or target DML. A claimed tracker row is completed even when its target row is already absent (or no longer matches the operation's update assumptions), and the loop continues according to claimed tracker rows rather than affected target rows. Any target DML failure rolls back the in-progress reset, claim, and target change together, preserving retry/resume safety.

### Step 4: Generate Cleanup Script
Always include a commented-out cleanup section at the end:

```sql
/*
-- ============================================
-- CLEANUP: Run after all processing is complete
-- ============================================

-- Verify completion
SELECT IsProcessed, COUNT(*) AS Cnt
FROM [BulkProcessTracking].[{yyyyMMddHHmm}_Tracker]
GROUP BY IsProcessed;

-- Drop tracking tables
DROP TABLE IF EXISTS [BulkProcessTracking].[{yyyyMMddHHmm}_InProgress];
DROP TABLE IF EXISTS [BulkProcessTracking].[{yyyyMMddHHmm}_Tracker];
*/
```

## Key Design Decisions (Explain to User)
- **Batch size ≤ 4,500** — Reduces lock-escalation risk; SQL Server can still escalate based on lock count, memory pressure, and concurrent workload
- **ROWLOCK, UPDLOCK hints** — Ensures row-level locking to avoid blocking other operations
- **TABLOCK on insert** — Faster bulk insert into the tracking table (it's exclusively ours)
- **WAITFOR DELAY** — 100ms pause between batches reduces pressure on busy systems
- **CHECKPOINT** — Only used in SIMPLE recovery model; reduces transaction log bloat
- **IsProcessed flag** — Makes the operation resumable if interrupted
- **Separate tracking schema** — Keeps operational tables isolated from business data

## Example Invocations

### Update 3M Records
```
Update 3 million records in dbo.Customer — set IsVerified = 1 where SignupDate < '2025-01-01'
```
Output: Setup + Insert script (filter by SignupDate) + Update script (SET IsVerified = 1)

### Insert 5M Records into Staging
```
Add 5M rows from dbo.Transaction into a tracking table for processing, where Amount > 100
```
Output: Setup + Insert script with WHERE Amount > 100

### Delete Old Audit Records
```
Delete 10M records from Audit.EventLog where EventDate < '2024-06-01'
```
Output: Setup + Insert script + Delete script

### Bulk Update with Multiple Columns
```
Update 2M orders: set Status = 'Archived', ArchivedAt = SYSUTCDATETIME() where Status = 'Completed' and CompletedAt < '2025-01-01'
```
Output: Setup + Insert script + Update script with multi-column SET clause

## Output Format
Always output the scripts in this order:
1. **Setup script** (schema + tracking tables) — ready to run
2. **Insert script** (populate tracking table) — ready to run
3. **Update/Delete script** (if applicable) — ready to run
4. **Cleanup script** — commented out
5. **Index rebuild advice** (if applicable) — commented out

Each script should be in its own SQL code block with a clear header comment.
