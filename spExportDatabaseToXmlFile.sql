/*
*  Name : #spExportDatabaseToXmlFile
*  Description : Export database tables in xml files
*
*  Use stored procedure : #spExportTableToXmlFile, #spWriteStringToFile
*
*  Syntax :
*  EXEC #spExportTableToXmlFile @Path = 'C:\Temp\';
*  EXEC #spExportTableToXmlFile @Path = 'C:\Temp\', @TableFilter = 'Test%';
*  EXEC #spExportTableToXmlFile @Path = 'C:\Temp\', @SchemaFilter = '%dbo%', @TableFilter = 'Test%';
*
*/
CREATE OR ALTER PROCEDURE #spExportDatabaseToXmlFile
( @Path VARCHAR(1024)        
, @SchemaFilter VARCHAR(512) = NULL
, @TableFilter VARCHAR(512)  = NULL
, @CreateXSDFile INT         = 0
, @SafeMode INT              = 0
, @Debug INT                 = 0
)
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @SchemaName VARCHAR(512);
	DECLARE @TableName VARCHAR(512);
	SELECT s.name AS SchemaName
	,      t.name AS TableName
		INTO #TableToExport
	FROM       sys.tables  t
	INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
	WHERE (
			@SchemaFilter IS NULL
			OR s.name LIKE @SchemaFilter)
		AND (
			@TableFilter IS NULL
			OR t.name LIKE @TableFilter)

	WHILE (EXISTS (SELECT * FROM #TableToExport))
	BEGIN
		SELECT TOP 1 @SchemaName = SchemaName, @TableName = TableName FROM #TableToExport;
		DELETE FROM #TableToExport WHERE @SchemaName = SchemaName AND @TableName = TableName;
		EXEC #spExportTableToXmlFile @SchemaName    = @SchemaName
		,                            @TableName     = @TableName
		,                            @Path          = @Path
		,                            @CreateXSDFile = @CreateXSDFile
		,                            @SafeMode      = @SafeMode
		,                            @Debug         = @Debug;
	END
END
