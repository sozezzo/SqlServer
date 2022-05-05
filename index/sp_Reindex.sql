USE [master]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE   PROC [dbo].[sp_Reindex]
(
   @DatabaseName     NVARCHAR(250)  
 , @avg_fragmentation_in_percent_filter INT = 5  -- Below this value it does nothing! -- Best value : 5 = (5%)
 , @n_Index_to_fix   INT = 10               -- It will only fix the top #index order by fragmentation. It will fix at least 1.  
 , @run_now          INT = 0                -- 0 == it will only create sql script to re-index.
 , @ExecutionDelay   DATETIME = '00:01:00'  -- delay between each execution: best value 00:05:00 == 5 minute

 -- Filters
 , @TableNameList    VARCHAR(MAX) = NULL    -- List of tables to check the indexies
 , @CountRows        INT = 100              -- Table Count Rows - below this value il will ignored
 , @CountPages       INT = 800              -- Table size in pages - below this value il will ignored

 -- ReIndex options
 , @ReorganizeLevel  INT = 5                -- Reorganize level 5%
 , @RebuildLevel     INT = 30               -- Rebuild level 30%  
 , @FillFactor       INT = 85               -- Defaut Fill factor  
 , @Allow_on_locks   INT = 0                -- Force to change Alow_page_locks and allow_row_locks to 'ON' 
 , @BackupLog        INT = 0                -- if reindex is done >>  0: do not backup log, 1: Backup log if LOG_BACKUP status, 2: TO DO Backup log 

 -- Debug mode
 , @debug            INT = 0
)
AS
BEGIN

	set nocount on;

--#region Select data

	CREATE TABLE #tbIndexTofix ( [DatabaseName] [nvarchar](128) NULL, [SchemaName] [sysname] NOT NULL, [TableName] [sysname] NOT NULL, [IndexName] [sysname] NULL, [allow_page_locks] [bit] NULL, [allow_row_locks] [bit] NULL, [RowCount] [bigint] NULL, [database_id] [smallint] NULL, [object_id] [int] NULL, [index_id] [int] NULL, [partition_number] [int] NULL, [index_type_desc] [nvarchar](60) NULL, [alloc_unit_type_desc] [nvarchar](60) NULL, [index_depth] [tinyint] NULL, [index_level] [tinyint] NULL, [avg_fragmentation_in_percent] [float] NULL, [fragment_count] [bigint] NULL, [avg_fragment_size_in_pages] [float] NULL, [page_count] [bigint] NULL, [IndexSqlToFix] [nvarchar](MAX) NULL )

	DECLARE @sqlIndexTofix as nvarchar(max);
	SET @sqlIndexTofix = '
use [@DatabaseName];
SELECT db_name() AS DatabaseName, sys.schemas.name AS SchemaName, sys.tables.name AS TableName, sys.indexes.name AS IndexName, sys.indexes.allow_page_locks, sys.indexes.allow_row_locks, totalRows.[RowCount] AS [RowCount], IDXPS.database_id, IDXPS.object_id, IDXPS.index_id, IDXPS.partition_number, IDXPS.index_type_desc, IDXPS.alloc_unit_type_desc, IDXPS.index_depth, IDXPS.index_level, IDXPS.avg_fragmentation_in_percent, IDXPS.fragment_count, IDXPS.avg_fragment_size_in_pages, IDXPS.page_count, CAST(NULL AS NVARCHAR(MAX)) AS IndexSqlToFix
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, NULL) AS IDXPS INNER JOIN sys.indexes ON sys.indexes.object_id = IDXPS.object_id AND sys.indexes.index_id = IDXPS.index_id INNER JOIN sys.tables ON sys.indexes.object_id = sys.tables.object_id INNER JOIN sys.schemas ON sys.tables.schema_id = sys.schemas.schema_id INNER JOIN (
SELECT object_id, SUM(row_count) AS [RowCount]
FROM sys.dm_db_partition_stats AS sdmvPTNS
GROUP BY object_id
) AS totalRows ON sys.tables.object_id = totalRows.object_id
WHERE (sys.tables.is_ms_shipped = 0) AND (sys.indexes.is_disabled = 0) AND (sys.indexes.is_hypothetical = 0);
';
	SET @sqlIndexTofix = REPLACE(@sqlIndexTofix, '@DatabaseName' ,@DatabaseName);

	INSERT INTO #tbIndexTofix ( [DatabaseName], [SchemaName], [TableName], [IndexName], [allow_page_locks], [allow_row_locks], [RowCount], [database_id], [object_id], [index_id], [partition_number], [index_type_desc], [alloc_unit_type_desc], [index_depth], [index_level], [avg_fragmentation_in_percent], [fragment_count], [avg_fragment_size_in_pages], [page_count], [IndexSqlToFix] )
	EXEC (@sqlIndexTofix)

	IF (@debug = 1)
	BEGIN
		SELECT '#tbIndexTofix',* FROM #tbIndexTofix
	END
--#endregion Select data

--#region Filters

	---------------------------------------
	-- Filters
	---------------------------------------

	-- NO heap tables
	DELETE FROM #tbIndexTofix WHERE index_type_desc = 'HEAP'

	-- NO Fragmentation
	DELETE FROM #tbIndexTofix WHERE avg_fragmentation_in_percent = 0

	-- Filter by table list
	IF (@TableNameList IS NOT NULL)
	DELETE FROM #tbIndexTofix WHERE (','+@TableNameList+',' NOT LIKE '%,'+#tbIndexTofix.TableName+',%' )

	-- Filter by Table Count Rows
	DELETE FROM #tbIndexTofix WHERE [RowCount] < @CountRows

	-- Filter by Table Count Pages
	DELETE FROM #tbIndexTofix WHERE [page_count] < @CountPages

	-- Filter by avg fragmentation in percent filter
	DELETE FROM #tbIndexTofix WHERE [avg_fragmentation_in_percent] < @avg_fragmentation_in_percent_filter
 
--#endregion Filters

--#region Create Script

	UPDATE #tbIndexTofix
	SET IndexSqlToFix = 
	   CASE WHEN IndexName IS NULL THEN
		CASE
		WHEN avg_fragmentation_in_percent > @RebuildLevel
		THEN 'ALTER TABLE ['+SchemaName+'].['+TableName+'] REBUILD;'
		ELSE ''
		END
	   ELSE
		CASE
		WHEN avg_fragmentation_in_percent < @ReorganizeLevel THEN ''
		WHEN avg_fragmentation_in_percent BETWEEN @ReorganizeLevel and @RebuildLevel THEN
		  'ALTER INDEX ['+IndexName+'] ON ['+SchemaName+'].['+TableName+'] REORGANIZE PARTITION = ALL;'
		WHEN avg_fragmentation_in_percent > @RebuildLevel THEN
		  'ALTER INDEX ['+IndexName+'] ON ['+SchemaName+'].['+TableName+'] REBUILD PARTITION = ALL WITH (FILLFACTOR = ' + CAST(@FillFactor AS VARCHAR(3) )+');'
		ELSE '--'
		END
	   END

	---------------------------------------
	IF (@Allow_on_locks = 1)
	BEGIN
		UPDATE #tbIndexTofix
		SET IndexSqlToFix = 
		CASE WHEN allow_page_locks = 0 THEN 'ALTER INDEX ['+IndexName+'] ON ['+SchemaName+'].['+TableName+'] SET ( ALLOW_PAGE_LOCKS = ON );' ELSE '' END+
		CASE WHEN allow_row_locks  = 0 THEN 'ALTER INDEX ['+IndexName+'] ON ['+SchemaName+'].['+TableName+'] SET ( ALLOW_ROW_LOCKS = ON );' ELSE '' END+
		IndexSqlToFix
		WHERE allow_page_locks = 0 OR allow_row_locks = 0;
	END
	ELSE
	BEGIN
		DELETE FROM #tbIndexTofix WHERE allow_page_locks = 0 OR allow_row_locks = 0;
	END

--#endregion Create Script

	---------------------------------------
	-- Delete when nothing to do
	DELETE FROM #tbIndexTofix WHERE IndexSqlToFix = '';

	-- Fix database name
	UPDATE #tbIndexTofix SET IndexSqlToFix = 'use [' + @DatabaseName + '];' + IndexSqlToFix;

	DECLARE @ReindexDone INT = 0
	---------------------------------------
	WHILE (EXISTS(SELECT * FROM #tbIndexTofix))
	BEGIN

--#region Create/Execute Script

		SET @ReindexDone = 1;

		DECLARE @d datetime
		DECLARE @msg AS NVARCHAR(MAX) = '';
		DECLARE @sql AS NVARCHAR(MAX) = '';
		DECLARE @SchemaName AS NVARCHAR(MAX) = '';
		DECLARE @TableName AS NVARCHAR(MAX) = '';
		DECLARE @IndexName AS NVARCHAR(MAX) = '';
		DECLARE @page_count BIGINT = 0;
		DECLARE @avg_fragmentation_in_percent AS NVARCHAR(MAX) = '';
	
		select TOP 1 
		  @sql = IndexSqlToFix
		, @SchemaName = SchemaName 
		, @TableName  = TableName 
		, @IndexName  = IndexName 
		, @avg_fragmentation_in_percent = avg_fragmentation_in_percent
		, @page_count = page_count
		from #tbIndexTofix order by [rowCount]*(avg_fragmentation_in_percent*avg_fragmentation_in_percent)/1000.0 DESC;
		delete from #tbIndexTofix where  @sql = IndexSqlToFix;
	
		SET @d = getutcdate();
		RAISERROR ('', 0, 1) WITH NOWAIT;

		SET @msg = '-- Index : [' + @IndexName + '] at ['+@SchemaName+'].['+@TableName+']- fragmentation in percent : ' + @avg_fragmentation_in_percent; RAISERROR (@msg, 0, 1) WITH NOWAIT;
		IF (@run_now = 1)
		BEGIN
			SET @msg = '-- '+CONVERT(nvarchar(100),getdate(),121); RAISERROR (@msg, 0, 1) WITH NOWAIT;
		END

		IF (@run_now = 0) RAISERROR ('PRINT ''-- ''+CONVERT(nvarchar(100),getdate(),121);', 0, 1) WITH NOWAIT;
		RAISERROR (@sql, 0, 1) WITH NOWAIT;
  
		IF (@run_now = 1)
		BEGIN
			EXEC(@sql);
			SET @msg = '-- execution time : ' + CAST(DATEDIFF(MILLISECOND, @d , getutcdate()) as nvarchar(100)) + ' ms'; RAISERROR (@msg, 0, 1) WITH NOWAIT;
		END

		SET @msg = 'WAITFOR DELAY '''+ CONVERT(NVARCHAR(50),@ExecutionDelay, 8)+''';';RAISERROR (@msg, 0, 1) WITH NOWAIT;
		IF (@run_now = 1) WAITFOR DELAY @ExecutionDelay;
	
		-- Max index to fix
		SET @n_Index_to_fix = @n_Index_to_fix - 1
		IF (@n_Index_to_fix <1) break;
--#endregion Create/Execute Script
	END

--#region Backup log_backup

	IF (@ReindexDone = 1 AND @BackupLog > 0)
	BEGIN
		IF (( EXISTS (select * from sys.databases where recovery_model = 1 AND log_reuse_wait > 0 AND [name] = @DatabaseName)) OR @BackupLog = 2 )
		BEGIN
			select @sql = 'BACKUP LOG ['+@DatabaseName+'] TO  DISK = N''NUL'' WITH NOFORMAT, INIT, SKIP, NOREWIND, NOUNLOAD,  STATS = 10;'
			PRINT @sql;
			IF (@run_now = 1)
			BEGIN
				EXEC(@sql);
			END
		END
	END

--#endregion Backup log_backup

END
GO


