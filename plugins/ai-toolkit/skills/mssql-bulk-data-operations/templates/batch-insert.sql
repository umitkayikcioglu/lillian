/*
PURPOSE (INSERT SCRIPT):
This script identifies and tracks records that need to be processed from a source table.

HOW IT WORKS:
1. Creates a tracking table with key values from the source table ([{Schema}].[{TableName}])
2. Processes records in configurable batches (default 4500 records per batch)
3. Works through the source table in [{KeyColumn}] order
4. Provides detailed progress reporting during execution
5. Implements regular checkpoints to minimize transaction log growth

CONFIGURATION:
- @BatchSize: Number of records processed in each batch (default: 4500)
- @MaxBatchesToProcess: Limit on total batches to process (0 = unlimited)
- @BatchesPerCheckpoint: How often to checkpoint to minimize log growth

USAGE NOTES:
- This script should be run FIRST to populate the tracking table
- The tracking table (BulkProcessTracking.{yyyyMMddHHmm}_Tracker) will be used by the UPDATE script
- Every brace token is a scaffold-time placeholder; resolve {Schema}, {TableName}, {KeyColumn}, {KeyType}, {FilterPredicate}, and {yyyyMMddHHmm} using the skill's canonical vocabulary before execution
- {KeyType} must resolve to INT or BIGINT. {FilterPredicate} is the required predicate body qualified with the mt alias; resolve it to 1 = 1 only when every source row is intentionally targeted.
*/

/*
-- Create the schema and tracking table
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'BulkProcessTracking')
BEGIN
    CREATE SCHEMA [BulkProcessTracking];
END
GO

-- Create the main tracking table (simplified version without IsProcessed)
CREATE TABLE [BulkProcessTracking].[{yyyyMMddHHmm}_Tracker]
(
    [{KeyColumn}] {KeyType} PRIMARY KEY,   -- Source key to be processed
    IsProcessed BIT NOT NULL DEFAULT 0   -- Flag to indicate whether the row has been processed (0 = Not Processed, 1 = Processed)
);

-- Create the index for performance on the IsProcessed column
CREATE NONCLUSTERED INDEX IDX_IsProcessed
ON [BulkProcessTracking].[{yyyyMMddHHmm}_Tracker](IsProcessed)
INCLUDE ([{KeyColumn}]);
*/

SET NOCOUNT ON;
SET XACT_ABORT ON;

-- Detect if CHECKPOINT is beneficial (only in SIMPLE recovery model, not Azure SQL/Hyperscale)
DECLARE @UseCheckpoint BIT = 0;
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = DB_NAME() AND recovery_model_desc = 'SIMPLE')
   AND SERVERPROPERTY('EngineEdition') NOT IN (5, 8) -- 5 = Azure SQL Database, 8 = Azure SQL Managed Instance
BEGIN
    SET @UseCheckpoint = 1;
    RAISERROR(N'CHECKPOINT enabled (SIMPLE recovery model detected)', 0, 1) WITH NOWAIT;
END
ELSE
BEGIN
    RAISERROR(N'CHECKPOINT disabled (FULL/BULK_LOGGED recovery or Azure SQL detected)', 0, 1) WITH NOWAIT;
END

-- Snapshot the filtered key range. A strict keyset cursor avoids key + 1 overflow at INT/BIGINT maxima.
DECLARE @MinID BIGINT =
(
    SELECT MIN(mt.[{KeyColumn}])
    FROM [{Schema}].[{TableName}] AS mt
    WHERE ({FilterPredicate})
);
DECLARE @MaxID BIGINT =
(
    SELECT MAX(mt.[{KeyColumn}])
    FROM [{Schema}].[{TableName}] AS mt
    WHERE ({FilterPredicate})
);
DECLARE @LastProcessedID BIGINT =
(
    SELECT MAX(tt.[{KeyColumn}])
    FROM [BulkProcessTracking].[{yyyyMMddHHmm}_Tracker] AS tt
);

DECLARE @MaxBatchesToProcess INT = 0;  -- 0 processes all eligible batches; a positive value limits this invocation to that many batches.
DECLARE @BatchSize INT = 4500; --Use batch processing (e.g., < 5,000 rows per batch) to avoid table locks during large operations.
DECLARE @BatchesPerCheckpoint INT = 20; -- Checkpoint after every n batches to minimize the impact on the transaction log (only when @UseCheckpoint = 1).

DECLARE @TotalRowCount BIGINT =
(
    SELECT COUNT_BIG(*)
    FROM [{Schema}].[{TableName}] AS mt
    WHERE ({FilterPredicate})
      AND mt.[{KeyColumn}] >= @MinID
      AND mt.[{KeyColumn}] <= @MaxID
      AND (@LastProcessedID IS NULL OR mt.[{KeyColumn}] > @LastProcessedID)
);

DECLARE @AffectedRowsInBatch INT = @BatchSize;
DECLARE @TotalProcessedRows BIGINT = 0;
DECLARE @ProgressMessage NVARCHAR(MAX);
DECLARE @ProgressPercentage INT;
DECLARE @QueryStartTime DATETIME2 = SYSDATETIME();
DECLARE @BatchStartTime DATETIME2;
DECLARE @BatchCounter BIGINT = 0;
DECLARE @CheckpointErrorMessage NVARCHAR(4000);

RAISERROR (N'Process starting...', 0, 1) WITH NOWAIT;

WHILE (@AffectedRowsInBatch > 0
       AND (@MaxBatchesToProcess = 0 OR @BatchCounter < @MaxBatchesToProcess)
       AND @MinID IS NOT NULL
       AND @MaxID IS NOT NULL
       AND (@LastProcessedID IS NULL OR @LastProcessedID < @MaxID))
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        SET @BatchStartTime = SYSDATETIME();
        SET @BatchCounter = @BatchCounter + 1;

        -- Insert batch of rows into the tracking table
        INSERT INTO [BulkProcessTracking].[{yyyyMMddHHmm}_Tracker] WITH (TABLOCK) ([{KeyColumn}])
        SELECT TOP (@BatchSize) mt.[{KeyColumn}]
        FROM [{Schema}].[{TableName}] AS mt
        WHERE ({FilterPredicate})
          AND mt.[{KeyColumn}] >= @MinID
          AND mt.[{KeyColumn}] <= @MaxID
          AND (@LastProcessedID IS NULL OR mt.[{KeyColumn}] > @LastProcessedID)
        ORDER BY mt.[{KeyColumn}];

        SET @AffectedRowsInBatch = @@ROWCOUNT;
        COMMIT TRANSACTION;

        -- Advance to the greatest successfully staged key without adding one (safe at BIGINT max).
        SELECT @LastProcessedID = MAX(tt.[{KeyColumn}])
        FROM [BulkProcessTracking].[{yyyyMMddHHmm}_Tracker] AS tt;

        -- Update progress counters
        SET @TotalProcessedRows = @TotalProcessedRows + @AffectedRowsInBatch;
        SET @ProgressPercentage = CASE
            WHEN @TotalRowCount > 0 THEN CONVERT(INT,
                (CONVERT(DECIMAL(38, 6), @TotalProcessedRows) * 100) /
                CONVERT(DECIMAL(38, 6), @TotalRowCount))
            ELSE 100
        END;

        -- Calculate and print progress
        SET @ProgressMessage = FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.fff') +
            N' [' + FORMAT(@BatchCounter,'0000000') +']' +
            N' [DurationMs: ' + CONVERT(NVARCHAR(30), DATEDIFF_BIG(MILLISECOND, @QueryStartTime, SYSDATETIME())) + ']' +
            N' [ElapsedMs: ' + CONVERT(NVARCHAR(30), DATEDIFF_BIG(MILLISECOND, @BatchStartTime, SYSDATETIME())) + ']' +
            N' [Processed: '  + FORMAT(@AffectedRowsInBatch,'0,0') + ']' +
            N' [TotalProcessed: '  + FORMAT(@TotalProcessedRows,'0,0') + ' / ' + FORMAT(@TotalRowCount,'N0') + ']' +
            N' [Progress: %d%%]';
        RAISERROR (@ProgressMessage, 0, 1, @ProgressPercentage) WITH NOWAIT;

        -- Perform a checkpoint after every n batches to minimize the transaction log size (only in SIMPLE recovery)
        IF (@UseCheckpoint = 1 AND @BatchCounter % @BatchesPerCheckpoint = 0)
        BEGIN
            BEGIN TRY
                RAISERROR (N'Checkpoint', 0, 1) WITH NOWAIT;
                CHECKPOINT;
            END TRY
            BEGIN CATCH
                SET @CheckpointErrorMessage = ERROR_MESSAGE();
                RAISERROR('Checkpoint failed: %s', 0, 1, @CheckpointErrorMessage) WITH NOWAIT;
            END CATCH
        END

        -- Slight delay between batches to minimize the impact on other operations in a busy environment.
        WAITFOR DELAY '00:00:00.100';
    END TRY
    BEGIN CATCH
        -- TODO: `The ROLLBACK TRANSACTION request has no corresponding BEGIN TRANSACTION.` will be thrown if the error occurs after the commit transaction above, such as `Divide by zero error encountered.`
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
        -- DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        -- DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        -- DECLARE @ErrorState INT = ERROR_STATE();
        -- RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        -- BREAK;
    END CATCH
END
