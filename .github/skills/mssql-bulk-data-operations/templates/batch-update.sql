/*
PURPOSE (UPDATE SCRIPT):
This script performs the actual updates on records previously identified by the INSERT script.

HOW IT WORKS:
1. Reads from the tracking table populated by the INSERT script
2. Processes records in configurable batches (default 4500 records per batch)
3. Uses a temporary "in-progress" table to track the current batch
4. Updates the source table ([{Schema}].[{TableName}]) with necessary changes
5. Marks records as processed in the tracking table
6. Provides detailed progress reporting during execution
7. Implements regular checkpoints to minimize transaction log growth

CONFIGURATION:
- @BatchSize: Number of records processed in each batch (default: 4500)
- @MaxBatchesToProcess: Limit on total batches to process (0 = unlimited)
- @BatchesPerCheckpoint: How often to checkpoint to minimize log growth

USAGE NOTES:
- This script should be run AFTER the INSERT script has populated the tracking table
- Applies {UpdateExpression} to the source table
- Every brace token is a scaffold-time placeholder; resolve it using the skill's canonical vocabulary before execution
- Consider disabling indexes before running large updates
- Cleanup tasks are commented out at the bottom when processing is complete
*/

/*
-- Optionally disable non-clustered indexes for better update performance
-- Resolve {IndexName} to the actual index name
-- ALTER INDEX [{IndexName}] ON [{Schema}].[{TableName}] DISABLE;
*/

/*
-- Create the in-progress table for batch processing
CREATE TABLE [BulkProcessTracking].[{yyyyMMddHHmm}_InProgress]
(
    [{KeyColumn}] {KeyType} PRIMARY KEY
);
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

-- Operation to perform batch updates
DECLARE @MaxBatchesToProcess INT = 0;  -- 0 processes all remaining batches; a positive value limits this invocation to that many batches.
DECLARE @BatchSize INT = 4500; --Use batch processing (e.g., < 5,000 rows per batch) to avoid table locks during large operations.
DECLARE @BatchesPerCheckpoint INT = 20; -- Checkpoint after every n batches to minimize the impact on the transaction log (only when @UseCheckpoint = 1).

DECLARE @TotalRowCount BIGINT;
SELECT @TotalRowCount = COUNT_BIG(*)
FROM [BulkProcessTracking].[{yyyyMMddHHmm}_Tracker] AS tt
WHERE tt.IsProcessed = 0;

IF @MaxBatchesToProcess > 0
BEGIN
    DECLARE @InvocationRowLimit BIGINT = CONVERT(BIGINT, @MaxBatchesToProcess) * CONVERT(BIGINT, @BatchSize);
    IF @TotalRowCount > @InvocationRowLimit
        SET @TotalRowCount = @InvocationRowLimit;
END

DECLARE @TrackerRowsInBatch INT = @BatchSize;
DECLARE @AffectedRowsInBatch INT = @BatchSize;
DECLARE @TotalProcessedRows BIGINT = 0;
DECLARE @ProgressMessage NVARCHAR(MAX);
DECLARE @ProgressPercentage INT;
DECLARE @QueryStartTime DATETIME2 = SYSDATETIME();
DECLARE @BatchStartTime DATETIME2;
DECLARE @BatchCounter BIGINT = 0;
DECLARE @CheckpointErrorMessage NVARCHAR(4000);

RAISERROR (N'Process starting...', 0, 1) WITH NOWAIT;

WHILE (@TrackerRowsInBatch > 0 AND (@MaxBatchesToProcess = 0 OR @BatchCounter < @MaxBatchesToProcess))
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        SET @BatchStartTime = SYSDATETIME();
        SET @BatchCounter = @BatchCounter + 1;

        -- Reset and populate the shared in-progress table under one transaction so
        -- another executor cannot interleave its reset or target DML with this claim.
        TRUNCATE TABLE [BulkProcessTracking].[{yyyyMMddHHmm}_InProgress];

        -- Update a batch of rows in tracking table where IsProcessed is false, mark them as processed, and output the IDs into progress table
        UPDATE TOP (@BatchSize) tt
        SET tt.IsProcessed = 1
        OUTPUT inserted.[{KeyColumn}] INTO [BulkProcessTracking].[{yyyyMMddHHmm}_InProgress] ([{KeyColumn}])
        FROM [BulkProcessTracking].[{yyyyMMddHHmm}_Tracker] AS tt WITH (ROWLOCK, UPDLOCK, READPAST)
        WHERE tt.IsProcessed = 0;

        SET @TrackerRowsInBatch = @@ROWCOUNT;

        IF @TrackerRowsInBatch = 0
        BEGIN
            COMMIT TRANSACTION;
            BREAK;
        END

        -- Update the target table using the selected batch of source keys
        UPDATE mt SET {UpdateExpression}
        FROM [{Schema}].[{TableName}] AS mt WITH (ROWLOCK, UPDLOCK)
        INNER JOIN [BulkProcessTracking].[{yyyyMMddHHmm}_InProgress] AS ttip ON ttip.[{KeyColumn}] = mt.[{KeyColumn}];

        SET @AffectedRowsInBatch = @@ROWCOUNT;
        COMMIT TRANSACTION;

        -- Update progress counters
        -- Progress follows completed tracker claims. Missing/stale target rows do not stop later claims.
        SET @TotalProcessedRows = @TotalProcessedRows + @TrackerRowsInBatch;
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
            N' [Tracked: '  + FORMAT(@TrackerRowsInBatch,'0,0') + ']' +
            N' [Updated: '  + FORMAT(@AffectedRowsInBatch,'0,0') + ']' +
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

/*
-- Re-enable any disabled indexes
-- ALTER INDEX [{IndexName}] ON [{Schema}].[{TableName}] REBUILD;

-- Clean up the temporary tables when completely done
DROP TABLE [BulkProcessTracking].[{yyyyMMddHHmm}_InProgress];
DROP TABLE [BulkProcessTracking].[{yyyyMMddHHmm}_Tracker];
*/

/*
-- Check the final status of the process
SELECT COUNT(*) FROM [BulkProcessTracking].[{yyyyMMddHHmm}_InProgress];
SELECT IsProcessed, COUNT(*) FROM [BulkProcessTracking].[{yyyyMMddHHmm}_Tracker] GROUP BY IsProcessed;
*/
