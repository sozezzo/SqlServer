/*
*  Name : #ChangeTracking_CreateSqlScript_To_SelectLastChangedData
*  Description : Create Script to select Change Tracking data
*
*  Syntax :
*
*    -- Simple select
*    EXEC #ChangeTracking_CreateSqlScript_To_SelectLastChangedData @SchemaName = 'dbo', @TableName = 'MyTable';
*
*    -- Add info of changed column
*    EXEC #ChangeTracking_CreateSqlScript_To_SelectLastChangedData @SchemaName = 'dbo', @TableName = 'MyTable', @AddInfo_HasChangedColumun=1;;
*
*/
CREATE PROCEDURE #ChangeTracking_CreateSqlScript_To_SelectLastChangedData 
(
@SchemaName VARCHAR(512),
@TableName  VARCHAR(512),
@VariableNameTo_CHANGE_VERSION VARCHAR(100) = '@LastChangeVersion',
@AddInfo_HasChangedColumun INT = 0 ,
@AddTemporaryTable INT = 0,
@ExecuteScript INT = 1
)
AS
BEGIN

SET NOCOUNT ON
DECLARE @LastChangeVersion BIGINT = 0;

-- Select primary key
DECLARE @Script_PrimaryKey VARCHAR(MAX) = ''collate DATABASE_DEFAULT;
DECLARE @Script_WherePrimaryKey VARCHAR(MAX) = '' collate DATABASE_DEFAULT;

SELECT 
 @Script_WherePrimaryKey = IIF(@Script_WherePrimaryKey = '' collate DATABASE_DEFAULT , '' collate DATABASE_DEFAULT , ' AND ' collate DATABASE_DEFAULT ) + 't.[' collate DATABASE_DEFAULT +c.[name]+'] = p.[' collate DATABASE_DEFAULT +c.[name]+']' collate DATABASE_DEFAULT
,@Script_PrimaryKey      = @Script_PrimaryKey + ', p.[' collate DATABASE_DEFAULT +c.[name]+']' collate DATABASE_DEFAULT 
FROM  sys.columns AS c INNER JOIN
    sys.indexes AS i INNER JOIN
    sys.index_columns AS ic ON i.index_id = ic.index_id AND i.object_id = ic.object_id ON c.column_id = ic.column_id AND c.object_id = ic.object_id INNER JOIN
    sys.tables AS t INNER JOIN
    sys.schemas AS s ON t.schema_id = s.schema_id ON i.object_id = t.object_id
WHERE t.name = @TableName
	AND s.name = @SchemaName
	AND i.is_primary_key = 1;

SET @Script_PrimaryKey =  ' -- Primary Key' collate DATABASE_DEFAULT + CHAR(13) + CHAR(10)+@Script_PrimaryKey;

-- Select no primary key
DECLARE @Script_NoPrimaryKey VARCHAR(MAX) = '' collate DATABASE_DEFAULT;
DECLARE @TemporaryTableSqlNoPrimaryKey VARCHAR(MAX) = '' collate DATABASE_DEFAULT;
SELECT @Script_NoPrimaryKey = @Script_NoPrimaryKey + ', t.[' collate DATABASE_DEFAULT + tc.[name]+']' collate DATABASE_DEFAULT
FROM sys.tables AS t INNER JOIN
    sys.schemas AS s ON t.schema_id = s.schema_id INNER JOIN
    sys.indexes AS i ON i.object_id = t.object_id INNER JOIN
    sys.index_columns AS ic ON ic.object_id = t.object_id AND i.index_id = ic.index_id INNER JOIN
    sys.columns AS c ON c.object_id = t.object_id AND ic.column_id = c.column_id INNER JOIN
    sys.columns AS tc ON t.object_id = tc.object_id AND c.name <> tc.name
WHERE t.name = @TableName
	AND s.name = @SchemaName
	AND i.is_primary_key = 1;
SET @Script_NoPrimaryKey = CHAR(13) + CHAR(10) + ' -- NO Primary Key' collate DATABASE_DEFAULT + CHAR(13) + CHAR(10) + @Script_NoPrimaryKey;

-- List has changed
DECLARE @Script_haschanged VARCHAR(MAX) = '' collate DATABASE_DEFAULT;
DECLARE @TemporaryTableSqlHasChanged VARCHAR(MAX) = '' collate DATABASE_DEFAULT;
DECLARE @TemporaryTableSqlHasChangedList VARCHAR(MAX) = '' collate DATABASE_DEFAULT;

IF (@AddInfo_HasChangedColumun = 1)
BEGIN
	SELECT @Script_haschanged = @Script_haschanged + ', CHANGE_TRACKING_IS_COLUMN_IN_MASK (COLUMNPROPERTY(OBJECT_ID(''' collate DATABASE_DEFAULT +s.name+'.' collate DATABASE_DEFAULT   +t.name+''' collate DATABASE_DEFAULT ), ''' collate DATABASE_DEFAULT +c.[name]+''', ''ColumnId''), p.sys_change_columns) AS [' collate DATABASE_DEFAULT +c.[name]+'_has_changed]' collate DATABASE_DEFAULT + CHAR(13) + CHAR(10),
	       @TemporaryTableSqlHasChanged = @TemporaryTableSqlHasChanged + ',[' collate DATABASE_DEFAULT +c.name+'_has_changed] [int] NULL' collate DATABASE_DEFAULT +CHAR(13)+CHAR(10),
		   @TemporaryTableSqlHasChangedList = @TemporaryTableSqlHasChangedList + ',[' collate DATABASE_DEFAULT +c.name+'_has_changed]' collate DATABASE_DEFAULT 
	FROM       sys.columns c
	INNER JOIN sys.tables  t ON c.object_id = t.object_id
	INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
	WHERE t.name = @TableName AND s.name = @SchemaName 
	SET @Script_haschanged = '-- Tracking columns have changed' collate DATABASE_DEFAULT + CHAR(13) + CHAR(10) + @Script_haschanged;
END

DECLARE @TemporaryTableIni NVARCHAR(MAX);
DECLARE @TemporaryTableList NVARCHAR(MAX) = '';
DECLARE @TemporaryTableEnd NVARCHAR(MAX);
IF (@AddTemporaryTable = 1)
BEGIN
	
	SET @TemporaryTableIni = '
DECLARE @tb TABLE (
 [SYS_CHANGE_VERSION] [bigint] NULL
,[SYS_CHANGE_CREATION_VERSION] [bigint] NULL
,[SYS_CHANGE_OPERATION] [nchar](1) NULL
,[SYS_CHANGE_COLUMNS] [varbinary](4100) NULL
'
	IF (@AddInfo_HasChangedColumun = 1)
	BEGIN
		SET @TemporaryTableIni = @TemporaryTableIni + @TemporaryTableSqlHasChanged;
	END

	SELECT 
	@TemporaryTableList = @TemporaryTableList+', ['+tc.name+']',
	@TemporaryTableIni = @TemporaryTableIni 
	+ ',['+tc.name+ '] '
	+ ty.name+ CASE WHEN ty.name IN('varchar', 'char', 'binary','varbinary') THEN CASE WHEN tc.max_length IS NULL OR tc.max_length IN(-1, 2147483647, 8000) THEN '(MAX)' ELSE '(' + CAST(tc.max_length AS NVARCHAR(10)) + ')' END WHEN ty.name IN('nvarchar', 'nchar', 'binary','varbinary') THEN CASE WHEN tc.max_length IS NULL OR tc.max_length IN(-1, 2147483647, 8000) THEN ' (MAX)' ELSE ' (' + CAST(tc.max_length / 2 AS NVARCHAR(10)) + ')' END WHEN ty.name IN('decimal', 'numeric') THEN ISNULL(' (' + CAST(tc.[precision] AS VARCHAR(30)) + ',' + CAST(tc.[Scale] AS VARCHAR(30)) + ')', '') ELSE '' END 
	+ CHAR(13) + CHAR(10)
	FROM sys.tables AS t INNER JOIN sys.schemas AS s ON t.schema_id = s.schema_id INNER JOIN sys.columns AS tc ON t.object_id = tc.object_id INNER JOIN sys.types AS ty 
	ON tc.user_type_id = ty.user_type_id 
	WHERE (t.name = @TableName)
	AND (s.name = @SchemaName)

	SET @TemporaryTableIni = @TemporaryTableIni + ');

INSERT INTO @tb ([SYS_CHANGE_VERSION], [SYS_CHANGE_CREATION_VERSION], [SYS_CHANGE_OPERATION], [SYS_CHANGE_COLUMNS]' +@TemporaryTableSqlHasChangedList+@TemporaryTableList+')'
	
	SET @TemporaryTableEnd = '
SELECT  @LastChangeVersion = MAX([SYS_CHANGE_VERSION]) FROM @tb;

SELECT [SYS_CHANGE_VERSION], [SYS_CHANGE_CREATION_VERSION], [SYS_CHANGE_OPERATION], [SYS_CHANGE_COLUMNS]' collate DATABASE_DEFAULT + @TemporaryTableSqlHasChangedList+@TemporaryTableList+' FROM @tb;
PRINT ''-- Next @LastChangeVersion value : '' + CAST(@LastChangeVersion AS NVARCHAR(50)); 
' collate DATABASE_DEFAULT ;

END
PRINT '-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --' collate DATABASE_DEFAULT;
PRINT '-- SQL Script to check Change-Tracking on table [' collate DATABASE_DEFAULT + @SchemaName + '].[' collate DATABASE_DEFAULT + @TableName + ']' collate DATABASE_DEFAULT; 
PRINT '-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --' collate DATABASE_DEFAULT;
DECLARE @Template VARCHAR(MAX) = 
'
-- Set last change version -- 
DECLARE @(VariableNameTo_CHANGE_VERSION) BIGINT = 0;

SET NOCOUNT ON;
@(TemporaryTableIni)
SELECT 
-- Change tracking columns
SYS_CHANGE_VERSION, SYS_CHANGE_CREATION_VERSION, SYS_CHANGE_OPERATION, SYS_CHANGE_COLUMNS
@(Script_haschanged)@(Script_PrimaryKey)@(Script_NoPrimaryKey)
FROM [@(SchemaName)].[@(TableName)] AS t RIGHT OUTER JOIN CHANGETABLE(CHANGES [@(SchemaName)].[@(TableName)], @(VariableNameTo_CHANGE_VERSION) ) AS p 
ON @(Script_WherePrimaryKey);
@(TemporaryTableEnd)
';


SET @Template = REPLACE(@Template,'@(VariableNameTo_CHANGE_VERSION)' collate DATABASE_DEFAULT , @VariableNameTo_CHANGE_VERSION);
SET @Template = REPLACE(@Template,'@(Script_haschanged)' collate DATABASE_DEFAULT , @Script_haschanged);
SET @Template = REPLACE(@Template,'@(SchemaName)' collate DATABASE_DEFAULT , @SchemaName);
SET @Template = REPLACE(@Template,'@(TableName)' collate DATABASE_DEFAULT , @TableName);
SET @Template = REPLACE(@Template,'@(Script_haschanged)' collate DATABASE_DEFAULT , @Script_haschanged);
SET @Template = REPLACE(@Template,'@(Script_PrimaryKey)' collate DATABASE_DEFAULT , @Script_PrimaryKey);
SET @Template = REPLACE(@Template,'@(Script_NoPrimaryKey)' collate DATABASE_DEFAULT , @Script_NoPrimaryKey);
SET @Template = REPLACE(@Template,'@(Script_WherePrimaryKey)' collate DATABASE_DEFAULT , @Script_WherePrimaryKey);
SET @Template = REPLACE(@Template,'@(TemporaryTableIni)' collate DATABASE_DEFAULT , @TemporaryTableIni);
SET @Template = REPLACE(@Template,'@(TemporaryTableEnd)' collate DATABASE_DEFAULT , @TemporaryTableEnd);

PRINT 'GO';
PRINT @Template;
PRINT 'GO';
IF (@ExecuteScript = 1)
BEGIN
	EXEC(@Template)
END

END
