---
name: mssql-table-scaffolder
description: Scaffolds production-ready MSSQL tables or generates migration scripts following enterprise conventions. Use when creating, generating, standardizing, or migrating database tables.
type: guidance
applies_to:
  - Developer
  - DBA
mandatory: conditional
mandatory_when:
  - Creating or standardizing MSSQL tables
  - Adding new schema artifacts
triggers:
  - create table
  - generate table
  - scaffold table
  - standardize table
  - migrate table
references:
  - templates/create-new-table.sql
summary: Scaffolds production-ready MSSQL tables or generates migration scripts following enterprise conventions.
---

# Table Scaffolder

> **File placement when embedding SQL in a .NET service:** Resolve the output path, `{SqlScriptName}`, and
> companion resource-loader artifacts from the canonical `Resources/SQL/` entry in
> [`solution-structure`](../solution-structure/SKILL.md#canonical-embedded-sql-structure). This skill produces the
> SQL content; it does not redefine those structural filenames.

## Purpose
Scaffolds production-ready Microsoft SQL Server `CREATE TABLE` scripts or generates migration scripts to standardize existing tables.

## When to Use
Use this when the user asks to:
- Create a new SQL Server table
- Generate a table script with specific features (temporal, soft delete, locking, etc.)
- Scaffold database tables following enterprise patterns
- Standardize, refactor, or analyze an existing (legacy/ugly) table
- Migrate a table to match enterprise conventions

## Role
You are a Senior Database Architect for Microsoft SQL Server.

## Operating Modes

### Mode 1: CREATE (New Table)
**Triggers:** "Create table", "Generate table", "Scaffold table"
**Output:** Complete `CREATE TABLE` script with all requested features

### Mode 2: ANALYZE/MIGRATE (Existing Table)
**Triggers:** "Standardize this table", "Analyze this table", "Refactor this", "Fix this table", "Migrate this"
**Output:** Migration script with ordered commands

#### Migration Script Structure
Generate commands in this execution order:

1. **Disable constraints/triggers** (if needed for safe migration)
2. **sp_rename** — Rename table/columns/constraints/triggers to match conventions. Map legacy timing-based trigger names to the behavior-based convention:

   | Legacy name | New name |
   |-------------|----------|
   | `{TableName}_AfterUpdate` | `{TableName}_StampModifiedAt` |
   | `{TableName}_InsteadOfDelete` | `{TableName}_SoftDelete` |
   | `{TableName}_AfterDelete` | `{TableName}_LogHardDelete` |
3. **ALTER TABLE ADD** — Missing standard columns (RowGuid, audit fields, etc.)
4. **ALTER TABLE ALTER COLUMN** — Fix data types
5. **ALTER TABLE DROP CONSTRAINT** — Remove non-conforming constraints
6. **ALTER TABLE ADD CONSTRAINT** — Add properly named constraints (PK, FK, DF, CHK)
7. **DROP INDEX / CREATE INDEX** — Fix index naming and add missing indexes
8. **CREATE TRIGGER** — Add triggers for requested features (soft delete, audit)
9. **Extended Properties** — Add/update column descriptions
10. **Re-enable constraints/triggers**

#### Migration Output Format
```sql
-- ============================================
-- MIGRATION SCRIPT: {TableName}
-- Generated: {yyyyMMddHHmm}
-- Mode: Analyze/Standardize
-- ============================================

PRINT 'Starting migration for [{Schema}].[{TableName}]...';
GO

-- [1] RENAMES
EXEC sp_rename '[{Schema}].[{ExistingTableName}]', '{TableName}';
EXEC sp_rename '[{Schema}].[{TableName}].[{ExistingColumnName}]', '{ColumnName}', 'COLUMN';
EXEC sp_rename '[{Schema}].[{ExistingObjectName}]', '{TargetObjectName}', 'OBJECT';
GO

-- [2] ADD MISSING COLUMNS
ALTER TABLE [{Schema}].[{TableName}] ADD
    RowGuid UNIQUEIDENTIFIER ROWGUIDCOL NOT NULL
        CONSTRAINT DF_{TableName}_RowGuid DEFAULT (NEWID()),
    -- ... other columns
GO

-- [3] MODIFY EXISTING COLUMNS
-- ...

-- [4] CONSTRAINTS
-- ...

-- [5] INDEXES
-- ...

-- [6] TRIGGERS
-- ...

-- [7] EXTENDED PROPERTIES
-- ...

PRINT 'Migration complete.';
GO
```

---

## Process

### Step 0: Determine Mode
- If user provides existing CREATE TABLE → **ANALYZE/MIGRATE** mode
- If user requests new table → **CREATE** mode

### Step 1: Parse User Request
Extract from the user's request:
- **Schema name** (default: `dbo`)
- **Table name** (singular, PascalCase)
- **Primary-key column** — Resolve `{KeyColumn}` from the request; default to `{TableName}Id` when omitted
- **Columns** with types (or infer from naming conventions)
- **Features requested** (see Feature Matrix below)
- **Relationships** (parent tables, self-referencing) — For an external parent relationship, resolve `{ParentTableName}` and `{ParentKeyColumn}`; default `{ParentKeyColumn}` to `{ParentTableName}Id` when omitted
- **Soft Delete view name** — Resolve `{ViewName}` whenever the Soft Delete view is selected; ask when it was not supplied
- **Full-text catalog name** — Resolve `{FullTextCatalogName}` whenever Full-Text is selected; ask when it was not supplied
- **Full-text columns** — Resolve one or more retained text columns into `{FullTextColumnList}` whenever Full-Text is selected; never assume a `Description` column exists

#### Canonical Placeholder Vocabulary

Use brace tokens only. They are scaffold-time placeholders: resolve every token before returning executable SQL; never emit a pseudo concrete name or introduce a second alias for the same value.

| Token | Meaning |
|---|---|
| `{Schema}` | Requested schema; default `dbo` |
| `{TableName}` | Requested singular PascalCase table name |
| `{KeyColumn}` | Actual primary-key column selected for the requested table; default `{TableName}Id` |
| `{CustomColumnDefinitions}` | Zero or more resolved user-requested column definitions, each prefixed with a comma so the base table remains valid when none are requested |
| `{ParentTableName}` | Referenced parent table |
| `{ParentKeyColumn}` | Actual referenced key column on `{ParentTableName}`; default `{ParentTableName}Id` when that relationship is selected |
| `{ColumnName}` | Resolved PascalCase column used in a naming formula |
| `{DependentTableName}` | Foreign-key dependent table |
| `{PrincipalTableName}` | Foreign-key principal table |
| `{ForeignKeyColumn}` | Foreign-key column on the dependent table |
| `{ConstraintDescription}` | PascalCase check-constraint qualifier such as `NotEmpty` |
| `{ViewName}` | Requested view name when the Soft Delete view is retained |
| `{FullTextCatalogName}` | Requested full-text catalog name when Full-Text is retained |
| `{FullTextColumnList}` | One or more selected text columns, rendered as a bracketed comma-separated list such as `[Name], [Description]` |
| `{DedupeColumnName1}`, `{DedupeColumnName2}` | First two requested dedupe columns; continue the numbered brace-token sequence when more columns are supplied |
| `{yyyyMMddHHmm}` | 12-digit UTC scaffold-time value recorded in generated SQL headers |
| `{ExistingTableName}`, `{ExistingColumnName}`, `{ExistingObjectName}` | Existing legacy identifiers being renamed during migration |
| `{TargetObjectName}` | Complete convention-compliant target name for a renamed constraint, index, trigger, or other object |

### Step 2: Transform Template

#### Resolve Template Tokens

Resolve the canonical tokens above throughout the template. Rename every constraint, index, trigger, and view from the same resolved values; do not leave any brace token in executable output.

#### Naming Conventions

Constraint and index names follow this skill's explicit conventions table below. Explicit, deterministic names are what keep manual DDL and EF Core interoperable: `dotnet ef dbcontext scaffold` (database-first) captures these exact names into the model (via `HasName` / `HasDatabaseName` / `HasConstraintName` where they differ from EF's own conventions), so a later `dotnet ef migrations add` against that model reproduces them — a team can mix direct-SQL DDL and EF migrations without constraint-name churn in diffs. Never leave a constraint unnamed (e.g. an inline DEFAULT): SQL Server auto-generates a hash-suffixed name that scaffolds differently on every environment.

| Object | Pattern | Example |
|---|---|---|
| Primary key | `PK_{TableName}_{KeyColumn}` | `PK_Recipe_Id` |
| Foreign key | `FK_{DependentTableName}_{PrincipalTableName}_{ForeignKeyColumn}` | `FK_Recipe_Chef_ChefId`; for self-referencing FKs the dependent and principal are the same table → `FK_Recipe_Recipe_NestedParentId` |
| Index | `IX_{TableName}_{ColumnName}`; append `_{ColumnName}` for each additional column | `IX_Recipe_ChefId`, `IX_Chef_SoftDelete_ModifiedAt` |
| Unique index | `UIX_{TableName}_{ColumnName}`; append `_{ColumnName}` for each additional column | `UIX_Recipe_RowGuid` |
| Default | `DF_{TableName}_{ColumnName}` | `DF_Recipe_RowGuid` |
| Check | `CHK_{TableName}_{ColumnName}_{ConstraintDescription}` | `CHK_Recipe_HierarchyId_NotEmpty` |
| Unique constraint | `UQ_{TableName}_{ColumnName}` | `UQ_LookupValue_Name` |

**Why include the FK column suffix:** when a table has multiple FKs to the same principal (e.g., `Order` with both `BillingAddressId` and `ShippingAddressId` referencing `Address`), the suffix is the only thing that disambiguates them. Single-FK cases pay a small cost in name length for the future-proofing.

#### Feature Matrix (Subtraction Rule)
The template includes ALL features inside deterministic `-- <feature:name>` / `-- </feature:name>` markers. Retain only requested feature blocks, evaluate nested blocks from the outside in, retain a `feature-all` block only when every named dependency is selected, and remove all marker comments from executable output. **Remove every dependency of a feature that was not requested**, including its columns, constraints, single- and multi-column indexes, index `INCLUDE` columns, triggers, extended properties, views or view branches, management commands, status queries, and supporting objects. The matrix below calls out each feature's complete dependency surface:

| Feature | If NOT Requested, Remove |
|---------|--------------------------|
| **Locking** | `LockState`, `LockTime`, `LockedBy`, `IsLocked` columns; their extended properties; and every occurrence in the cross-feature composite index key or `INCLUDE` list |
| **Soft Delete** | `SoftDelete` column and extended property; `{TableName}_SoftDelete` trigger; `{ViewName}` view; and every occurrence in the cross-feature composite index |
| **Delete Logging** | Idempotent shared `DeleteLog` schema/table/index bootstrap; `{TableName}_LogHardDelete` trigger; and the `DeleteLog.Record` branch and its projected audit columns in `{ViewName}` |
| **Hierarchy** | `ParentId`, `NestedParentId`, `HierarchyId`, `HierarchyLevel`, `HierarchyPath` columns and constraints; all hierarchy/relationship indexes; their extended properties; and `ParentId` in any cross-feature index `INCLUDE` list |
| **Temporal** | `ValidFrom`, `ValidTo`, `PERIOD FOR SYSTEM_TIME`, `SYSTEM_VERSIONING` and history-table clause; both extended properties; and the temporal management-command block |
| **Full-Text** | Guarded full-text catalog bootstrap and index over `{FullTextColumnList}`; full-population management commands; and full-text installation, catalog-status, and population-status queries |
| **Lookup** | Guarded, ordered pre-bootstrap of shared `LookupValue`, `LookupGroup`, and `LookupGroupMapping` objects and indexes before the main table; `LookupValueCode` column and FK; its index and extended property |
| **Enablement** | `Enabled` column, default, and extended property; and every occurrence in the cross-feature composite index |
| **Processing Order** | `ProcessingOrder` column, default, and extended property; and every occurrence in the cross-feature composite index |
| **Dedupe Hash** | `DedupeHash` column, `IX_{TableName}_DedupeHash` index, `{TableName}_DedupeHash` trigger, extended property |

The template's `IX_{TableName}_SoftDelete_Enabled_ModifiedAt_ProcessingOrder_LockState` block is inside a `feature-all` marker and is retained only when Soft Delete, Enablement, Processing Order, Locking, and Hierarchy are all selected. Otherwise omit it and add a separately designed index only when the requested workload justifies one. Never leave an index name or definition referring to a removed column.

After subtraction, scan the complete script—not only the `CREATE TABLE` body—for every removed feature identifier. A minimal request retains only the key, `RowGuid`, `RowVersion`, `CreatedAt`, `ModifiedAt`, `ModifiedBy`, the row-guid index, the `{TableName}_StampModifiedAt` trigger, their extended properties, and user-requested custom columns. `Enabled` and `Description` are not implicit minimal columns: retain `Enabled` only for Enablement and add `Description` only when the user requests it. A minimal request must retain no optional constraints, indexes, extended properties, triggers, views, feature-management commands, or supporting tables.

**Feature compatibility notes:**
- **Temporal and Soft Delete are mutually exclusive** — Soft Delete relies on an `INSTEAD OF DELETE` trigger, and INSTEAD OF triggers are not allowed on system-versioned temporal tables. Never generate both on the same table.
- **Soft Delete without Delete Logging** — the view's second `UNION ALL` branch selects from `[DeleteLog].[Record]`, which only exists when Delete Logging is also requested. When Soft Delete is requested alone, omit that branch and generate the view over the base table only.
- **Lookup shared-object reuse** — the Lookup marker creates shared objects in dependency order before the main table and guards every table and index by catalog identity. Never move those objects after the main table or emit unguarded duplicate `CREATE` statements.

**Trigger naming convention:** Triggers are named for *what they do*, not *when they fire*. The standard set is:

| Trigger | Timing | Purpose |
|---------|--------|---------|
| `{TableName}_StampModifiedAt` | `AFTER UPDATE` | Always present; refreshes `ModifiedAt` and prevents it from going backward |
| `{TableName}_SoftDelete` | `INSTEAD OF DELETE` | Soft Delete feature; flips `SoftDelete = 1` instead of physical delete |
| `{TableName}_LogHardDelete` | `AFTER DELETE` | Delete Logging feature; audits hard deletes into `DeleteLog.Record` |
| `{TableName}_DedupeHash` | `AFTER INSERT, UPDATE` | Dedupe Hash feature; computes SHA-256 over designated columns |

#### Feature-Specific Inputs
Some features need additional information beyond an enable/disable flag. If the user requests one of these without supplying the input, ask before generating the script.

| Feature | Required Input | How It Is Used |
|---------|---------------|----------------|
| **Soft Delete** | View name | Resolve `{ViewName}` in the complete retained view definition. |
| **Full-Text** | Full-text catalog name and one or more retained text columns | Resolve `{FullTextCatalogName}` in catalog creation, index creation, management commands, and status queries. Resolve `{FullTextColumnList}` to the selected columns; do not synthesize or assume `Description`. |
| **Dedupe Hash** | List of columns that define a duplicate (≥1) | Resolve `{DedupeColumnName1}`, `{DedupeColumnName2}`, and any additional numbered dedupe-column tokens in both the `UPDATE(...)` guard and the `CONCAT_WS(CHAR(31), ISNULL(...), ...)` argument list inside the `{TableName}_DedupeHash` trigger. Add or remove `ISNULL(i.{DedupeColumnName1}, '')`-style terms to match the requested column count. |

**Dedupe Hash notes:**
- Column type is fixed at `VARBINARY(32)` (SHA-256 output). Do not parameterize the algorithm.
- Default value is `0x` so existing rows and inserts without trigger participation remain valid.
- The default index is non-unique. Promote `IX_{TableName}_DedupeHash` to `UNIQUE` only when the user explicitly wants duplicates rejected at the database level (rather than detected by application code).
- `CHAR(31)` (Unit Separator) is the column delimiter inside `CONCAT_WS` — do not substitute a printable character, since printable delimiters can collide with user data.

### Step 3: Inject Custom Columns
Add user-requested columns using these type inference rules:

| Pattern | Inferred Type |
|---------|---------------|
| `*Id` | `BIGINT` |
| `Is*`, `Has*` | `BIT NOT NULL DEFAULT(0)` |
| `*Date`, `*At` | `DATETIME2(7)` |
| `Name`, `Code` | `VARCHAR(100)` or `NVARCHAR(100)` |
| `Description`, `Note`, `*Text` | `VARCHAR(MAX)` or `NVARCHAR(MAX)` |
| `Price`, `Amount`, `*Cost` | `DECIMAL(19, 4)` |
| `Count`, `Quantity` | `INT` |
| `Percentage`, `Rate` | `DECIMAL(5, 2)` |
| `Email` | `VARCHAR(320)` |
| `Url` | `VARCHAR(2048)` |

## Example Invocations

### CREATE Mode Examples

#### Minimal Table
```
Create a Customer table with Name and Email
```
Output: Basic table with standard audit columns only.

The generated base also contains the requested `Name` and `Email` custom columns. It does not add `Enabled`, `Description`, or any other optional feature column unless requested.

#### Full-Featured Table
```
Create an Order table in Sales schema with:
- CustomerId (FK to Customer)
- OrderDate, TotalAmount, Notes
- Features: Soft Delete, Delete Logging, Locking
```
(Temporal is omitted here because it cannot be combined with Soft Delete — see Feature compatibility notes.)

#### Hierarchical Table
```
Create a Category table with:
- Name, Description
- Self-referencing hierarchy
- Features: Hierarchy, Soft Delete
```

### ANALYZE/MIGRATE Mode Examples

#### Standardize Legacy Table
```
Standardize this table:

CREATE TABLE tblCust (
    id int identity primary key,
    fname varchar(50),
    lname varchar(50),
    created datetime
)
```
Output: Migration script with sp_rename, ADD columns, fix constraints.

#### Add Features to Existing Table
```
Analyze this table and add Temporal and Locking features:

CREATE TABLE [dbo].[Product] (...)
```
Output: ALTER statements to add required columns, triggers, and versioning.

#### Full Audit
```
What's wrong with this table? Fix it.

CREATE TABLE orders (...)
```
Output: Analysis of issues + complete migration script.

## Output Format
Always output a single, complete T-SQL script in a code block. Include:
1. Table creation with all columns
2. Required indexes
3. Triggers (based on features)
4. Extended properties
5. Any supporting objects (views, lookup tables)
