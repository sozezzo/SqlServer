GO
/*
 *
 * Returns the current size of each object on database and estimates the size for the requested compression state. 
 *
 * https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-estimate-data-compression-savings-transact-sql?view=sql-server-ver15
 *
 */

/* Filters */
DECLARE @SchemaName       sysname      = NULL
	  ,   @DataTableName    sysname      = NULL
	  ,   @data_compression nvarchar(60) = 'ROW' -- 'ROW', 'PAGE', 'NONE'
/* Filters */


SET NOCOUNT ON;

DECLARE @TableName sysname;

DROP TABLE IF EXISTS #results;
CREATE TABLE #results (
  [object_id]                                          int NULL
, [object_name]                                        sysname
, [schema_name]                                        sysname NULL
, [index_id]                                           int
, [IndexName]                                          sysname NULL
, [partition_number]                                   int
, [size_with_current_compression_setting(KB)]          bigint
, [size_with_requested_compression_setting(KB)]        bigint
, [sample_size_with_current_compression_setting(KB)]   bigint
, [sample_size_with_requested_compression_setting(KB)] bigint
, [data_compression]                                   nvarchar(60)
, [data_compression_per]                               float NULL
, [SavedSpace(KB)]                                     bigint
, [SqlScript]                                          nvarchar(MAX) NULL );

DROP TABLE IF EXISTS #tbTable;
CREATE TABLE #tbTable (
  [SchemaName] sysname
, [TableName]  sysname );

INSERT INTO #tbTable ( [SchemaName], [TableName] )
SELECT SCHEMA_NAME(t.schema_id)    [SchemaName]
,      [name]                   AS [TableName]
FROM sys.tables t
	WHERE
		(
			SCHEMA_NAME(t.schema_id) = @SchemaName
			OR @SchemaName IS NULL)
		AND (
			t.name = @DataTableName
			OR @DataTableName IS NULL);

WHILE ((SELECT count(*) AS n
	FROM #tbTable) > 0)
BEGIN

	SELECT @SchemaName = [SchemaName]
	,      @DataTableName = [TableName]
	FROM #tbTable;
	DELETE FROM #tbTable
		WHERE
			@SchemaName = [SchemaName]
			AND @DataTableName = [TableName];

	INSERT INTO #results ( [object_name], [schema_name], [index_id], [partition_number], [size_with_current_compression_setting(KB)], [size_with_requested_compression_setting(KB)], [sample_size_with_current_compression_setting(KB)], [sample_size_with_requested_compression_setting(KB)] )
	EXEC sp_estimate_data_compression_savings @schema_name = @SchemaName, @object_name = @DataTableName, @index_id = NULL, @partition_number = NULL, @data_compression = 'ROW' ;

END

UPDATE #results
SET [object_id] =            t.object_id
,   [IndexName] =            i.[name]
,   [data_compression] =     @data_compression
,   [data_compression_per] = IIF([size_with_requested_compression_setting(KB)] <> 0, (1.0*[size_with_requested_compression_setting(KB)])/[size_with_current_compression_setting(KB)],0)
,   SqlScript =              'ALTER TABLE ['+[schema_name]+'].'+[object_name]+' REBUILD PARTITION = ALL  WITH (DATA_COMPRESSION = '+@data_compression+');'
,   [SavedSpace(KB)] =       [size_with_current_compression_setting(KB)]-[size_with_requested_compression_setting(KB)]
FROM sys.indexes i INNER JOIN sys.tables t
	ON	i.object_id = t.object_id INNER JOIN #results r
	ON	r.object_name = t.name
	AND r.[schema_name] = schema_name(t.schema_id);

SELECT [object_id]
,      [object_name]
,      [schema_name]
,      [index_id]
,      [IndexName]
,      [partition_number]
,      [size_with_current_compression_setting(KB)]
,      [size_with_requested_compression_setting(KB)]
,      [sample_size_with_current_compression_setting(KB)]
,      [sample_size_with_requested_compression_setting(KB)]
,      [data_compression]
,      [data_compression_per]
,      [SavedSpace(KB)]
,      [SqlScript]
FROM #results
ORDER BY [SavedSpace(KB)] DESC;
GO


