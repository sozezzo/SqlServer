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
CREATE OR ALTER PROCEDURE #ChangeTracking_CreateSqlScript_To_SelectLastChangedData
(
@SchemaName VARCHAR(512),
@TableName  VARCHAR(512),
@VariableNameTo_CHANGE_VERSION VARCHAR(100) = '@LastChangeVersion',
@AddInfo_HasChangedColumun INT = 0 
)
AS
BEGIN

SET NOCOUNT ON
DECLARE @LastChangeVersion BIGINT = 0;

-- Select primary key
DECLARE @Script_PrimaryKey VARCHAR(MAX) = '';
DECLARE @Script_WherePrimaryKey VARCHAR(MAX) = '';
SELECT @Script_PrimaryKey = @Script_PrimaryKey + ', p.['+c.[name]+']',
@Script_WherePrimaryKey = IIF(@Script_WherePrimaryKey = '', '', ' AND ') + 't.['+c.[name]+'] = p.['+c.[name]+']'
FROM sys.tables AS t INNER JOIN
    sys.schemas AS s ON t.schema_id = s.schema_id INNER JOIN
    sys.indexes AS i ON i.object_id = t.object_id INNER JOIN
    sys.index_columns AS ic ON ic.object_id = t.object_id INNER JOIN
    sys.columns AS c ON c.object_id = t.object_id AND ic.column_id = c.column_id
WHERE t.name = @TableName
	AND s.name = @SchemaName
	AND i.is_primary_key = 1;
SET @Script_PrimaryKey = @Script_PrimaryKey + ' -- Primary Key' + CHAR(13) + CHAR(10);

-- Select no primary key
DECLARE @Script_NoPrimaryKey VARCHAR(MAX) = '';
SELECT @Script_NoPrimaryKey = @Script_NoPrimaryKey + ', t.['+tc.[name]+']'  
FROM sys.tables AS t INNER JOIN
    sys.schemas AS s ON t.schema_id = s.schema_id INNER JOIN
    sys.indexes AS i ON i.object_id = t.object_id INNER JOIN
    sys.index_columns AS ic ON ic.object_id = t.object_id AND i.index_id = ic.index_id INNER JOIN
    sys.columns AS c ON c.object_id = t.object_id AND ic.column_id = c.column_id INNER JOIN
    sys.columns AS tc ON t.object_id = tc.object_id AND c.name <> tc.name
WHERE t.name = @TableName
	AND s.name = @SchemaName
	AND i.is_primary_key = 1;
SET @Script_NoPrimaryKey = @Script_NoPrimaryKey + ' -- NO Primary Key';

-- List has changed
DECLARE @Script_haschanged VARCHAR(MAX) = '';
IF (@AddInfo_HasChangedColumun = 1)
SELECT @Script_haschanged = @Script_haschanged + ', CHANGE_TRACKING_IS_COLUMN_IN_MASK (COLUMNPROPERTY(OBJECT_ID('''+s.name+'.'+t.name+'''), '''+c.[name]+''', ''ColumnId''), p.sys_change_columns) AS ['+c.[name]+'_has_changed]' + CHAR(13) + CHAR(10)
FROM       sys.columns c
INNER JOIN sys.tables  t ON c.object_id = t.object_id
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE t.name = @TableName AND s.name = @SchemaName 

DECLARE @Template VARCHAR(MAX) = 
'
DECLARE @(VariableNameTo_CHANGE_VERSION) BIGINT = 0;
SELECT 
SYS_CHANGE_VERSION, SYS_CHANGE_CREATION_VERSION, SYS_CHANGE_OPERATION, SYS_CHANGE_COLUMNS
@(Script_haschanged)@(Script_PrimaryKey)@(Script_NoPrimaryKey)
FROM [@(SchemaName)].[@(TableName)] AS t RIGHT OUTER JOIN CHANGETABLE(CHANGES [@(SchemaName)].[@(TableName)], @(VariableNameTo_CHANGE_VERSION) ) AS p 
ON @(Script_WherePrimaryKey);
';

SET @Template = REPLACE(@Template,'@(VariableNameTo_CHANGE_VERSION)', @VariableNameTo_CHANGE_VERSION);
SET @Template = REPLACE(@Template,'@(Script_haschanged)', @Script_haschanged);
SET @Template = REPLACE(@Template,'@(SchemaName)', @SchemaName);
SET @Template = REPLACE(@Template,'@(TableName)', @TableName);
SET @Template = REPLACE(@Template,'@(Script_haschanged)', @Script_haschanged);
SET @Template = REPLACE(@Template,'@(Script_PrimaryKey)', @Script_PrimaryKey);
SET @Template = REPLACE(@Template,'@(Script_NoPrimaryKey)', @Script_NoPrimaryKey);
SET @Template = REPLACE(@Template,'@(Script_WherePrimaryKey)', @Script_WherePrimaryKey);

PRINT @Template
EXEC(@Template)

END
GO
