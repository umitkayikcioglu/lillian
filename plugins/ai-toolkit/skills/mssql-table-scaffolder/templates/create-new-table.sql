/*
Every brace token is a scaffold-time placeholder; resolve it using the canonical vocabulary in the Table Scaffolder skill before execution.
Generated: {yyyyMMddHHmm}
Required: {Schema}, {TableName}, and {KeyColumn}; resolve {KeyColumn} to {TableName}Id when omitted.
Required custom-column rendering: {CustomColumnDefinitions}; resolve it to zero or more definitions, each beginning with a comma.
Feature-specific: {ParentTableName}, {ParentKeyColumn}, {ViewName}, {FullTextCatalogName},
{FullTextColumnList}, {DedupeColumnName1}, and {DedupeColumnName2}. Remove each unused feature block as directed by the subtraction rule.
When an external parent relationship is selected, resolve {ParentKeyColumn} to {ParentTableName}Id when omitted.
After subtraction, remove every dependent column, constraint, index key/INCLUDE reference, extended property, view branch, management command, status query, and supporting object for each omitted feature.
*/

-- <feature:lookup>
-- Shared lookup objects are bootstrapped before the main table that references them.
IF OBJECT_ID(N'[{Schema}].[LookupValue]', N'U') IS NULL
BEGIN
    CREATE TABLE [{Schema}].[LookupValue]
    (
        Code TINYINT NOT NULL CONSTRAINT PK_LookupValue_Code PRIMARY KEY CLUSTERED (Code ASC),
        Name VARCHAR(50) NOT NULL CONSTRAINT UQ_LookupValue_Name UNIQUE,
        Description VARCHAR(512) NULL
    );
END
GO

IF OBJECT_ID(N'[{Schema}].[LookupGroup]', N'U') IS NULL
BEGIN
    CREATE TABLE [{Schema}].[LookupGroup]
    (
        Code TINYINT NOT NULL CONSTRAINT PK_LookupGroup_Code PRIMARY KEY CLUSTERED (Code ASC),
        Name VARCHAR(50) NOT NULL CONSTRAINT UQ_LookupGroup_Name UNIQUE,
        Description VARCHAR(512) NULL
    );
END
GO

IF OBJECT_ID(N'[{Schema}].[LookupGroupMapping]', N'U') IS NULL
BEGIN
    CREATE TABLE [{Schema}].[LookupGroupMapping]
    (
        Id SMALLINT IDENTITY(1, 1) NOT NULL CONSTRAINT PK_LookupGroupMapping_Id PRIMARY KEY CLUSTERED (Id ASC),
        LookupGroupCode TINYINT NOT NULL,
        LookupValueCode TINYINT NOT NULL,
        CONSTRAINT FK_LookupGroupMapping_LookupValue_LookupValueCode FOREIGN KEY (LookupValueCode)
            REFERENCES [{Schema}].[LookupValue](Code) ON UPDATE CASCADE ON DELETE CASCADE,
        CONSTRAINT FK_LookupGroupMapping_LookupGroup_LookupGroupCode FOREIGN KEY (LookupGroupCode)
            REFERENCES [{Schema}].[LookupGroup](Code) ON UPDATE CASCADE ON DELETE CASCADE
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[{Schema}].[LookupGroupMapping]') AND name = N'IX_LookupGroupMapping_LookupGroupCode')
    CREATE NONCLUSTERED INDEX IX_LookupGroupMapping_LookupGroupCode ON [{Schema}].[LookupGroupMapping](LookupGroupCode);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[{Schema}].[LookupGroupMapping]') AND name = N'IX_LookupGroupMapping_LookupValueCode')
    CREATE NONCLUSTERED INDEX IX_LookupGroupMapping_LookupValueCode ON [{Schema}].[LookupGroupMapping](LookupValueCode);
GO
-- </feature:lookup>

CREATE TABLE [{Schema}].[{TableName}]
(
    [{KeyColumn}] BIGINT IDENTITY(1, 1) NOT FOR REPLICATION NOT NULL
        CONSTRAINT PK_{TableName}_{KeyColumn}
            PRIMARY KEY CLUSTERED ([{KeyColumn}] ASC),
    RowGuid UNIQUEIDENTIFIER ROWGUIDCOL NOT NULL
        CONSTRAINT DF_{TableName}_RowGuid
            DEFAULT (NEWID()),
    [RowVersion] ROWVERSION,
    CreatedAt DATETIME2(7) NOT NULL
        CONSTRAINT DF_{TableName}_CreatedAt
            DEFAULT (SYSUTCDATETIME()),
    ModifiedAt DATETIME2(7) NOT NULL
        CONSTRAINT DF_{TableName}_ModifiedAt
            DEFAULT (SYSUTCDATETIME()),
    ModifiedBy VARCHAR(261) NOT NULL
        CONSTRAINT DF_{TableName}_ModifiedBy
            DEFAULT (SUSER_SNAME())
-- <feature:soft-delete>
    , SoftDelete BIT NOT NULL     -- WARNING: Remove if using temporal tables or cascading FK constraints (INSTEAD OF trigger limitation).
        CONSTRAINT DF_{TableName}_SoftDelete
            DEFAULT (0)
-- </feature:soft-delete>
-- <feature:enablement>
    , [Enabled] BIT NOT NULL
        CONSTRAINT DF_{TableName}_Enabled
            DEFAULT (0)
-- </feature:enablement>
-- <feature:processing-order>
    , ProcessingOrder TINYINT NOT NULL
        CONSTRAINT DF_{TableName}_ProcessingOrder
            DEFAULT (0)
-- </feature:processing-order>
-- <feature:locking>
    , LockState TINYINT NULL
    , LockTime DATETIME2(7) NULL
    , LockedBy VARCHAR(261) NULL
    , IsLocked AS CAST(
                 CASE
                     WHEN  LockState IS NOT NULL
                           AND LockState > 0
                           AND DATEDIFF(MINUTE, LockTime, SYSUTCDATETIME()) <= 15
                     THEN 1
                     ELSE 0
                 END
                 AS BIT)           -- WARNING: Keyword 'PERSISTED' cannot be specified after 'END' when the time-based condition is present, as the expression is non-deterministic.
-- </feature:locking>
-- <feature:lookup>
    , LookupValueCode TINYINT NULL
        CONSTRAINT FK_{TableName}_LookupValue_LookupValueCode
            FOREIGN KEY (LookupValueCode)
            REFERENCES [{Schema}].[LookupValue] (Code)
            ON DELETE SET NULL  -- WARNING: Remove if using temporal tables
            ON UPDATE CASCADE  -- WARNING: Remove if using temporal tables
-- </feature:lookup>
-- <feature:hierarchy>
    , ParentId BIGINT NULL
        CONSTRAINT FK_{TableName}_{ParentTableName}_ParentId
            FOREIGN KEY (ParentId)
            REFERENCES [{Schema}].[{ParentTableName}] ([{ParentKeyColumn}])
            ON DELETE CASCADE   -- WARNING: Remove if using temporal tables
            ON UPDATE CASCADE  -- WARNING: Remove if using temporal tables
    , NestedParentId BIGINT NULL
        CONSTRAINT FK_{TableName}_{TableName}_NestedParentId
            FOREIGN KEY (NestedParentId)
            REFERENCES [{Schema}].[{TableName}] ([{KeyColumn}])
            ON DELETE SET NULL   -- WARNING: Remove if using temporal tables
            ON UPDATE NO ACTION -- WARNING: Remove if using temporal tables
    , [HierarchyId] HIERARCHYID NOT NULL
        CONSTRAINT DF_{TableName}_HierarchyId
            DEFAULT (HIERARCHYID::GetRoot())
        CONSTRAINT CHK_{TableName}_HierarchyId_NotEmpty
            CHECK ([HierarchyId].ToString() <> '')
    , HierarchyLevel AS [HierarchyId].GetLevel() PERSISTED
    , HierarchyPath AS [HierarchyId].ToString() PERSISTED
-- </feature:hierarchy>
-- <feature:temporal>
    -- System-versioned temporal tables to automatically track historical changes and deletions.
    , ValidFrom DATETIME2(7) GENERATED ALWAYS AS ROW START HIDDEN
    , ValidTo DATETIME2(7) GENERATED ALWAYS AS ROW END HIDDEN
    , PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo)
-- </feature:temporal>
-- <feature:dedupe-hash>
    -- SHA-256 hash of designated dedup columns; auto-populated by the `{TableName}_DedupeHash` trigger for duplicate detection.
    , DedupeHash VARBINARY(32) NOT NULL
        CONSTRAINT DF_{TableName}_DedupeHash
            DEFAULT (0x)
-- </feature:dedupe-hash>
    {CustomColumnDefinitions}
)
-- <feature:temporal>
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = [{Schema}].[{TableName}History], DATA_CONSISTENCY_CHECK = ON))
-- </feature:temporal>
;
GO

CREATE UNIQUE NONCLUSTERED INDEX UIX_{TableName}_RowGuid ON [{Schema}].[{TableName}](RowGuid)
GO

-- <feature:hierarchy>
-- Breadth-first: by level, then ID
CREATE NONCLUSTERED INDEX IX_{TableName}_HierarchyLevel_BreadthFirst
    ON [{Schema}].[{TableName}]([HierarchyLevel], [{KeyColumn}]);
GO

-- Depth-first: hierarchy traversal by HierarchyId path
CREATE UNIQUE NONCLUSTERED INDEX UIX_{TableName}_HierarchyId_DepthFirst
    ON [{Schema}].[{TableName}]([HierarchyId]);
GO

-- Foreign key index (Self-referencing parent entity)
CREATE NONCLUSTERED INDEX IX_{TableName}_NestedParentId
    ON [{Schema}].[{TableName}](NestedParentId);
GO

-- Foreign key index (External table reference)
CREATE NONCLUSTERED INDEX IX_{TableName}_ParentId
    ON [{Schema}].[{TableName}](ParentId);
GO
-- </feature:hierarchy>

-- <feature-all:soft-delete,enablement,processing-order,locking,hierarchy>
-- Column 'IsLocked' is a computed column with non-deterministic expression and cannot be used in an index or statistics or as a partition key because it is non-deterministic.
CREATE NONCLUSTERED INDEX IX_{TableName}_SoftDelete_Enabled_ModifiedAt_ProcessingOrder_LockState
    ON [{Schema}].[{TableName}]([SoftDelete] ASC, [Enabled] ASC, [ModifiedAt] DESC, [ProcessingOrder] ASC, [LockState] ASC)
    INCLUDE ([{KeyColumn}], ParentId, LockedBy);
GO
-- </feature-all:soft-delete,enablement,processing-order,locking,hierarchy>

-- <feature:lookup>
CREATE NONCLUSTERED INDEX IX_{TableName}_LookupValueCode
    ON [{Schema}].[{TableName}](LookupValueCode);
GO
-- </feature:lookup>

-- <feature:dedupe-hash>
-- Non-unique by default; promote to UNIQUE to enforce duplicate prevention at the database level.
CREATE NONCLUSTERED INDEX IX_{TableName}_DedupeHash
    ON [{Schema}].[{TableName}](DedupeHash);
GO
-- </feature:dedupe-hash>

CREATE TRIGGER [{Schema}].[{TableName}_StampModifiedAt] ON [{Schema}].[{TableName}]
	AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF ((SELECT TRIGGER_NESTLEVEL()) > 1) RETURN;

    IF NOT UPDATE(ModifiedAt)
    BEGIN
        UPDATE  entity
        SET     entity.ModifiedAt = CASE
                                        WHEN SYSUTCDATETIME() >= d.ModifiedAt
                                        THEN SYSUTCDATETIME()
                                        ELSE d.ModifiedAt
                                    END
        FROM    [{Schema}].[{TableName}] AS entity
            JOIN INSERTED AS i
                ON entity.[{KeyColumn}] = i.[{KeyColumn}]
            JOIN DELETED AS d
                ON d.[{KeyColumn}] = i.[{KeyColumn}];
    END
    ELSE
    BEGIN
        UPDATE  entity
        SET     entity.ModifiedAt = CASE
                                        WHEN i.ModifiedAt >= d.ModifiedAt
                                        THEN i.ModifiedAt
                                        ELSE d.ModifiedAt
                                    END
        FROM    [{Schema}].[{TableName}] AS entity
            JOIN INSERTED AS i
                ON entity.[{KeyColumn}] = i.[{KeyColumn}]
            JOIN DELETED AS d
                ON d.[{KeyColumn}] = i.[{KeyColumn}];
    END
END
GO

-- <feature:dedupe-hash>
-- Computes a SHA-256 hash from designated dedup columns to enable duplicate detection.
-- Resolve {DedupeColumnName1}, {DedupeColumnName2} (and add additional numbered terms in CONCAT_WS) to the columns that define a duplicate.
-- CHAR(31) (Unit Separator) is used as a delimiter to prevent collisions across column boundaries.
CREATE TRIGGER [{Schema}].[{TableName}_DedupeHash] ON [{Schema}].[{TableName}]
    AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF ((SELECT TRIGGER_NESTLEVEL()) > 1) RETURN;

    IF NOT (UPDATE([{DedupeColumnName1}]) OR UPDATE([{DedupeColumnName2}]))
        RETURN;

    UPDATE  entity
    SET     entity.DedupeHash = CAST(HASHBYTES('SHA2_256',
                CONCAT_WS(CHAR(31),
                    ISNULL(i.[{DedupeColumnName1}], ''),
                    ISNULL(i.[{DedupeColumnName2}], '')
                )
            ) AS VARBINARY(32))
    FROM    [{Schema}].[{TableName}] AS entity
        JOIN INSERTED AS i
            ON entity.[{KeyColumn}] = i.[{KeyColumn}];
END
GO

-- </feature:dedupe-hash>
-- <feature:soft-delete>
-- Soft delete; marks records as deleted by updating a 'SoftDelete' flag instead of physically removing data.
-- Note: This prevents the row from ever being physically deleted by a standard DELETE statement.
-- Consequently, the '{TableName}_LogHardDelete' trigger below will NEVER fire unless this trigger is disabled or bypassed.

CREATE TRIGGER [{Schema}].[{TableName}_SoftDelete] ON [{Schema}].[{TableName}]
   INSTEAD OF DELETE
AS
BEGIN
	SET NOCOUNT ON;

	UPDATE entity
	SET entity.SoftDelete = 1
	FROM [{Schema}].[{TableName}] AS entity
	INNER JOIN DELETED AS d
		ON entity.[{KeyColumn}] = d.[{KeyColumn}];
END
GO

-- </feature:soft-delete>
-- <feature:delete-logging>
-- Dedicated schema for the shared hard-delete audit table.
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'DeleteLog')
    EXEC ('CREATE SCHEMA [DeleteLog]');
GO

IF OBJECT_ID(N'[DeleteLog].[Record]', N'U') IS NULL
BEGIN
CREATE TABLE [DeleteLog].[Record]
(
    Id BIGINT IDENTITY(1, 1) NOT FOR REPLICATION NOT NULL
        CONSTRAINT PK_Record_Id
            PRIMARY KEY CLUSTERED (Id ASC),
    RowGuid UNIQUEIDENTIFIER ROWGUIDCOL NOT NULL
        CONSTRAINT DF_Record_RowGuid
            DEFAULT (NEWID()),
    [RowVersion] ROWVERSION,
    DeletedAt DATETIME2(7) NOT NULL
        CONSTRAINT DF_Record_DeletedAt
            DEFAULT (SYSUTCDATETIME()),
    DeletedBy VARCHAR(261) NOT NULL
        CONSTRAINT DF_Record_DeletedBy
            DEFAULT (SUSER_SNAME()),
    FullyQualifiedTableName VARCHAR(261) NOT NULL,
    EntityId BIGINT NOT NULL
);
END
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'[DeleteLog].[Record]')
      AND name = N'UIX_Record_RowGuid'
)
    CREATE UNIQUE NONCLUSTERED INDEX UIX_Record_RowGuid ON [DeleteLog].[Record](RowGuid);
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'[DeleteLog].[Record]')
      AND name = N'IX_Record_DeletedAt_FullyQualifiedTableName'
)
    CREATE NONCLUSTERED INDEX IX_Record_DeletedAt_FullyQualifiedTableName
        ON [DeleteLog].[Record] ([DeletedAt] ASC, [FullyQualifiedTableName] ASC)
        INCLUDE (EntityId);
GO

-- External delete logging; physically deletes records and logs deletions into an external audit/logging table.
CREATE TRIGGER [{Schema}].[{TableName}_LogHardDelete] ON [{Schema}].[{TableName}]
   AFTER DELETE
AS
BEGIN
	SET NOCOUNT ON;

	INSERT [DeleteLog].[Record] (
	    FullyQualifiedTableName,
		EntityId,
        DeletedAt,
        DeletedBy
	)
	SELECT
        '{Schema}.{TableName}',
        d.[{KeyColumn}],
        SYSUTCDATETIME(),
        d.ModifiedBy
	FROM DELETED AS d
END
GO

-- </feature:delete-logging>
-- <feature:soft-delete>
-- NOTE: This view cannot be indexed (no unique clustered index) because indexed views do not support UNION ALL.
CREATE VIEW [{Schema}].[{ViewName}]
WITH SCHEMABINDING
AS
SELECT
    entity.[{KeyColumn}]
  , entity.RowGuid
  , entity.[RowVersion]
  , entity.CreatedAt
  , entity.ModifiedAt
  , entity.ModifiedBy
  , CONVERT(bit, 0) AS HardDelete
  , CAST(NULL AS BIGINT) AS DeleteLogId
  , CAST(NULL AS VARCHAR(261)) AS FullyQualifiedTableName
FROM
    [{Schema}].[{TableName}] AS entity
-- <feature-all:soft-delete,delete-logging>
UNION ALL
SELECT
    dl.EntityId
  , dl.RowGuid
  , dl.[RowVersion]
  , NULL         AS CreatedAt
  , dl.DeletedAt AS ModifiedAt
  , dl.DeletedBy AS ModifiedBy
  , CONVERT(bit, 1) AS HardDelete
  , dl.Id AS DeleteLogId
  , dl.FullyQualifiedTableName
FROM
    [DeleteLog].[Record] AS dl
WHERE
    dl.FullyQualifiedTableName = '{Schema}.{TableName}';
-- </feature-all:soft-delete,delete-logging>
GO
-- </feature:soft-delete>

EXEC sys.sp_addextendedproperty @name = N'MS_Description',
                                @value = N'Auto-generated identity key uniquely identifying each record.',
                                @level0type = N'SCHEMA', @level0name = N'{Schema}',
                                @level1type = N'TABLE',  @level1name = N'{TableName}',
                                @level2type = N'COLUMN', @level2name = N'{KeyColumn}';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description',
                                @value = N'ROWGUIDCOL uniquely identifying each row for replication purposes.',
                                @level0type = N'SCHEMA', @level0name = N'{Schema}',
                                @level1type = N'TABLE',  @level1name = N'{TableName}',
                                @level2type = N'COLUMN', @level2name = N'RowGuid';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description',
                                @value = N'Automatically generated timestamp for row versioning; useful for concurrency checks.',
                                @level0type = N'SCHEMA', @level0name = N'{Schema}',
                                @level1type = N'TABLE',  @level1name = N'{TableName}',
                                @level2type = N'COLUMN', @level2name = N'RowVersion';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description',
                                @value = N'UTC timestamp when the record was created.',
                                @level0type = N'SCHEMA', @level0name = N'{Schema}',
                                @level1type = N'TABLE',  @level1name = N'{TableName}',
                                @level2type = N'COLUMN', @level2name = N'CreatedAt';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description',
                                @value = N'UTC timestamp indicating the last modification of the entity record.',
                                @level0type = N'SCHEMA', @level0name = N'{Schema}',
                                @level1type = N'TABLE',  @level1name = N'{TableName}',
                                @level2type = N'COLUMN', @level2name = N'ModifiedAt';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description',
                                @value = N'Username of the user who last modified the entity record.',
                                @level0type = N'SCHEMA', @level0name = N'{Schema}',
                                @level1type = N'TABLE',  @level1name = N'{TableName}',
                                @level2type = N'COLUMN', @level2name = N'ModifiedBy';
GO

-- <feature:soft-delete>
EXEC sys.sp_addextendedproperty @name = N'MS_Description',
                                @value = N'Indicates logical deletion; 1 if the entity is logically deleted, otherwise 0.',
                                @level0type = N'SCHEMA', @level0name = N'{Schema}',
                                @level1type = N'TABLE',  @level1name = N'{TableName}',
                                @level2type = N'COLUMN', @level2name = N'SoftDelete';
GO
-- </feature:soft-delete>

-- <feature:enablement>
EXEC sys.sp_addextendedproperty @name = N'MS_Description',
                                @value = N'Indicates whether the entity is currently enabled; 1 if enabled, otherwise 0.',
                                @level0type = N'SCHEMA', @level0name = N'{Schema}',
                                @level1type = N'TABLE',  @level1name = N'{TableName}',
                                @level2type = N'COLUMN', @level2name = N'Enabled';
GO
-- </feature:enablement>

-- <feature:processing-order>
EXEC sys.sp_addextendedproperty @name = N'MS_Description',
                                @value = N'Determines the processing order of entities; lower values are processed first.',
                                @level0type = N'SCHEMA', @level0name = N'{Schema}',
                                @level1type = N'TABLE',  @level1name = N'{TableName}',
                                @level2type = N'COLUMN', @level2name = N'ProcessingOrder';
GO
-- </feature:processing-order>

-- <feature:locking>
EXEC sys.sp_addextendedproperty @name = N'MS_Description',
                                @value = N'Indicates the type or level of lock applied to the entity. `NULL` = never executed; `0` = executed and completed; `1-255` = custom-defined process stages.',
                                @level0type = N'SCHEMA', @level0name = N'{Schema}',
                                @level1type = N'TABLE',  @level1name = N'{TableName}',
                                @level2type = N'COLUMN', @level2name = N'LockState';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description',
                                @value = N'UTC timestamp indicating when the entity was locked; null if unlocked.',
                                @level0type = N'SCHEMA', @level0name = N'{Schema}',
                                @level1type = N'TABLE',  @level1name = N'{TableName}',
                                @level2type = N'COLUMN', @level2name = N'LockTime';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description',
                                @value = 'Hostname indicating the machine that currently holds the lock on the entity.',
                                @level0type = N'SCHEMA', @level0name = N'{Schema}',
                                @level1type = N'TABLE',  @level1name = N'{TableName}',
                                @level2type = N'COLUMN', @level2name = N'LockedBy';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description',
                                @value = N'Computed column indicating lock presence; 1 if locked, otherwise 0.',
                                @level0type = N'SCHEMA', @level0name = N'{Schema}',
                                @level1type = N'TABLE',  @level1name = N'{TableName}',
                                @level2type = N'COLUMN', @level2name = N'IsLocked';
GO
-- </feature:locking>

-- <feature:lookup>
EXEC sys.sp_addextendedproperty @name = N'MS_Description',
                                @value = N'Foreign key referencing the `LookupValue` table; nullable. Identifies a specific lookup value associated with the entity.',
                                @level0type = N'SCHEMA', @level0name = N'{Schema}',
                                @level1type = N'TABLE',  @level1name = N'{TableName}',
                                @level2type = N'COLUMN', @level2name = N'LookupValueCode';
GO
-- </feature:lookup>

-- <feature:hierarchy>
EXEC sys.sp_addextendedproperty @name = N'MS_Description',
                                @value = N'Foreign key linking to the parent entity in `{ParentTableName}`; nullable.',
                                @level0type = N'SCHEMA', @level0name = N'{Schema}',
                                @level1type = N'TABLE',  @level1name = N'{TableName}',
                                @level2type = N'COLUMN', @level2name = N'ParentId';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description',
                                @value = N'Self-referencing foreign key indicating the immediate parent.',
                                @level0type = N'SCHEMA', @level0name = N'{Schema}',
                                @level1type = N'TABLE',  @level1name = N'{TableName}',
                                @level2type = N'COLUMN', @level2name = N'NestedParentId';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description',
                                @value = N'HierarchyID representing the position of the entity within a hierarchical structure.',
                                @level0type = N'SCHEMA', @level0name = N'{Schema}',
                                @level1type = N'TABLE',  @level1name = N'{TableName}',
                                @level2type = N'COLUMN', @level2name = N'HierarchyId';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description',
                                @value = N'Computed column representing the depth level within the hierarchy; root is level 0.',
                                @level0type = N'SCHEMA', @level0name = N'{Schema}',
                                @level1type = N'TABLE',  @level1name = N'{TableName}',
                                @level2type = N'COLUMN', @level2name = N'HierarchyLevel';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description',
                                @value = N'Computed string representation of the hierarchy path, derived from HierarchyId.',
                                @level0type = N'SCHEMA', @level0name = N'{Schema}',
                                @level1type = N'TABLE',  @level1name = N'{TableName}',
                                @level2type = N'COLUMN', @level2name = N'HierarchyPath';
GO
-- </feature:hierarchy>

-- <feature:temporal>
EXEC sys.sp_addextendedproperty @name = N'MS_Description',
                                @value = N'System-versioned temporal table column marking the start time of row validity period.',
                                @level0type = N'SCHEMA', @level0name = N'{Schema}',
                                @level1type = N'TABLE',  @level1name = N'{TableName}',
                                @level2type = N'COLUMN', @level2name = N'ValidFrom';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description',
                                @value = N'System-versioned temporal table column marking the end time of row validity period.',
                                @level0type = N'SCHEMA', @level0name = N'{Schema}',
                                @level1type = N'TABLE',  @level1name = N'{TableName}',
                                @level2type = N'COLUMN', @level2name = N'ValidTo';
GO
-- </feature:temporal>

-- <feature:dedupe-hash>
EXEC sys.sp_addextendedproperty @name = N'MS_Description',
                                @value = N'SHA-256 hash of designated dedup columns; auto-populated by the AFTER INSERT/UPDATE trigger to enable duplicate detection.',
                                @level0type = N'SCHEMA', @level0name = N'{Schema}',
                                @level1type = N'TABLE',  @level1name = N'{TableName}',
                                @level2type = N'COLUMN', @level2name = N'DedupeHash';
GO
-- </feature:dedupe-hash>


-- <feature:temporal>
/*
-- TEMPORAL TABLE MANAGEMENT COMMANDS
-- ===================================
-- [1] Temporarily Disable Versioning (preserves period columns)
ALTER TABLE [{Schema}].[{TableName}] SET (SYSTEM_VERSIONING = OFF);
GO

-- [2] Permanently Remove Temporal Definitions (requires redefining to enable again)
ALTER TABLE [{Schema}].[{TableName}] DROP PERIOD FOR SYSTEM_TIME;
GO
*/
-- </feature:temporal>

-- <feature:full-text>
IF NOT EXISTS (SELECT 1 FROM sys.fulltext_catalogs WHERE name = N'{FullTextCatalogName}')
    CREATE FULLTEXT CATALOG [{FullTextCatalogName}] AS DEFAULT;
GO

CREATE FULLTEXT INDEX ON [{Schema}].[{TableName}] ({FullTextColumnList})
KEY INDEX PK_{TableName}_{KeyColumn} ON [{FullTextCatalogName}]
WITH STOPLIST = SYSTEM;
GO

/*
ALTER FULLTEXT INDEX ON [{Schema}].[{TableName}] START FULL POPULATION;
ALTER FULLTEXT INDEX ON [{Schema}].[{TableName}] PAUSE POPULATION;
ALTER FULLTEXT INDEX ON [{Schema}].[{TableName}] RESUME POPULATION;
ALTER FULLTEXT INDEX ON [{Schema}].[{TableName}] REBUILD;
DROP FULLTEXT INDEX ON [{Schema}].[{TableName}]
*/

/*
-- FULL-TEXT CATALOG MANAGEMENT & STATUS CHECKS
-- =============================================
-- [1] Verify if Full-Text Search is installed on the server.
SELECT SERVERPROPERTY('IsFullTextInstalled') AS IsFullTextInstalled;

-- [2] Check catalog population completion status, current activity, and indexed item count.
SELECT FULLTEXTCATALOGPROPERTY('{FullTextCatalogName}', 'PopulateCompletion') AS PopulateCompletion,
    CASE FULLTEXTCATALOGPROPERTY('{FullTextCatalogName}', 'PopulateStatus')
        WHEN 0 THEN 'Idle (no population running)'
        WHEN 1 THEN 'Full population in progress'
        WHEN 2 THEN 'Paused'
        WHEN 3 THEN 'Throttled (paused due to resource limit)'
        WHEN 4 THEN 'Recovering'
        WHEN 5 THEN 'Shutdown'
        WHEN 6 THEN 'Incremental population in progress'
        WHEN 7 THEN 'Building index'
        WHEN 8 THEN 'Disk full (population stopped)'
        WHEN 9 THEN 'Change Tracking (auto-population running)'
        ELSE 'Unknown'
    END AS PopulationStatus,
FORMAT(FULLTEXTCATALOGPROPERTY('{FullTextCatalogName}', 'ItemCount'),'N0') AS IndexedItemCount;

-- [3] Inspect ongoing full-text index populations, their types, statuses, and start times per table.
SELECT
    OBJECT_SCHEMA_NAME(p.table_id) AS SchemaName,
    OBJECT_NAME(p.table_id) AS TableName,
    CASE p.status
        WHEN 0 THEN 'Idle (no population running)'
        WHEN 1 THEN 'Full population in progress'
        WHEN 2 THEN 'Paused'
        WHEN 3 THEN 'Throttled (paused due to resource limit)'
        WHEN 4 THEN 'Recovering'
        WHEN 5 THEN 'Shutdown'
        WHEN 6 THEN 'Incremental population in progress'
        WHEN 7 THEN 'Building index'
        WHEN 8 THEN 'Disk full (population stopped)'
        WHEN 9 THEN 'Change Tracking (auto-population running)'
        ELSE 'Unknown'
    END AS PopulationStatus,
    CASE p.population_type
        WHEN 1 THEN 'Full'
        WHEN 2 THEN 'Incremental'
        WHEN 3 THEN 'Manual'
        WHEN 4 THEN 'Auto'
        ELSE 'Unknown'
    END AS PopulationType,
    p.start_time AS StartTime
FROM sys.dm_fts_index_population AS p;
*/
-- </feature:full-text>
