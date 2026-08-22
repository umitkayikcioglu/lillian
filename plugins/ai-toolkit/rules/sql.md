---
trigger: glob
globs: **/*.sql
---

# SQL Instructions

This file is the canonical authority for SQL implementation conventions.

## MSSQL naming

- Use PascalCase identifiers.
- Use singular table names.
- Do not add prefixes or abbreviations.

For table creation and migrations, use `../skills/mssql-table-scaffolder/SKILL.md`. Its table-, constraint-,
and index-specific patterns extend the SQL baseline in this instruction; they do not replace it.

## SQL Script Rules (all .sql files)

1. **Table aliases** - Use table aliases consistently for table references in SQL statements. For MSSQL `UPDATE` and `DELETE`, the target table must be referenced through the `FROM` clause with an alias, and all `WHERE` clause columns must be prefixed with that alias.
2. **Transaction error handling** - When a script performs transactional data changes, use `SET XACT_ABORT ON`, wrap the transaction in `TRY...CATCH`, roll back when `@@TRANCOUNT > 0`, and rethrow with `THROW`.

## Embedded SQL Resources Pattern

When SQL is used from C# code, it must be stored as embedded resource files, not as inline strings.
Embedded SQL placement and filenames come from
[`Canonical embedded SQL structure`](../skills/solution-structure/SKILL.md#canonical-embedded-sql-structure).
Follow [`Resources/SQL/`](../skills/dotnet-service-generator/references/standard-service.md#resourcessql) for
project-file embedding and loader implementation.

### SQL Script Guidelines

1. **Header comments** - Document purpose, parameters, and security notes
2. **Parameter naming** - Use `@p0`, `@p1`, etc. for positional parameters (matches `sp_executesql` convention)
3. **Input validation** - Validate required parameters with `THROW`
4. **Schema validation** - Check table/schema existence before operations
5. **Use QUOTENAME()** - For dynamic object names to prevent injection
6. **DEBUG mode** - Always include a debug parameter and commented test block

### Transaction Error Handling Pattern

Use this pattern for transactional SQL scripts:

```sql
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;
    --...
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
```

### DEBUG Mode Pattern

Every embedded SQL script **must** include a debug mode that allows developers to test the script in SSMS without executing:

```sql
--! Feature Name - Operation Description
--! Parameters:
--!   @p0 (NVARCHAR) - Schema name
--!   @p1 (NVARCHAR) - Table name
--!   @p2 (BIT)      - Debug mode (1 = print SQL without executing)

SET NOCOUNT ON;

/*
-- DEBUG: Uncomment this block to test the script in SSMS
DECLARE @p0 NVARCHAR(128) = N'dbo';
DECLARE @p1 NVARCHAR(128) = N'TestTable';
DECLARE @p2 BIT = 1;  -- Set to 1 to see the generated SQL without executing
*/

DECLARE @SchemaName NVARCHAR(128) = @p0;
DECLARE @TableName NVARCHAR(128) = @p1;
DECLARE @Debug BIT = COALESCE(@p2, 0);

-- ... validation logic ...

DECLARE @Sql NVARCHAR(MAX) = N'...';
DECLARE @Id BIGINT = 123;

IF @Debug = 1
BEGIN
    PRINT '-- DEBUG: Generated SQL';
    RAISERROR (N'==> [DEBUG] @Sql: %s, @Id: %I64d', 0, 1, @Sql, @Id) WITH NOWAIT;
END
ELSE
BEGIN
    EXEC sp_executesql @Sql;
END
```

**Benefits:**
- Developers can test SQL logic directly in SSMS
- See exactly what SQL will be generated before execution
- Debug without modifying production code
- Validate parameter combinations safely

### Reference Implementation

[Ruya.EntityFrameworkCore.SqlServer's BatchLock implementation](https://github.com/cilerler/ruya/tree/main/src/Ruya.EntityFrameworkCore.SqlServer/BatchLock) contains the reference SQL examples for this pattern.
