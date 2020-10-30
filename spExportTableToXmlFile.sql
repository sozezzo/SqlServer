/*
*  Name : #spExportTableToXmlFile
*  Description : Export table in xml file
*
*  Use stored procedure : #spWriteStringToFile
*
*  Syntax :
*  EXEC #spExportTableToXmlFile @SchemaName = 'dbo', @TableName = 'User', @Path = 'C:\Temp\', @Filename = 'user.xml';
*
*/
CREATE OR ALTER PROCEDURE #spExportTableToXmlFile
( @SchemaName VARCHAR(255)
, @TableName VARCHAR(255) 
, @Path VARCHAR(255)      
, @FileName VARCHAR(512)   = NULL
, @Debug INT               = 0
)
AS
BEGIN
    
	SET NOCOUNT ON;

	IF (@Filename IS NULL)
	BEGIN
		SET @Filename = @SchemaName+'.' COLLATE DATABASE_DEFAULT +@TableName+'.xml' COLLATE DATABASE_DEFAULT;
	END
	-- TODO : Clean up invalided chars

	DECLARE @Template NVARCHAR(MAX) = '

PRINT ''-- Export Table to Xml File : [@(SchemaName)].[@(TableName)]''
PRINT ''-- '' + CONVERT(VARCHAR(50), GETDATE(), 121);
DECLARE @xml varchar(max);
SET @xml = (select * from [@(SchemaName)].[@(TableName)] FOR XML AUTO, ROOT (''@(SchemaName).@(TableName)''))
EXEC #spWriteStringToFile @String = @xml, @Path = ''@(Path)'', @Filename  = ''@(Filename)'';
' COLLATE DATABASE_DEFAULT

	SET @Template = REPLACE(@Template,'@(SchemaName)' COLLATE DATABASE_DEFAULT , @SchemaName);
	SET @Template = REPLACE(@Template,'@(TableName)' COLLATE DATABASE_DEFAULT , @TableName);
	SET @Template = REPLACE(@Template,'@(Path)' COLLATE DATABASE_DEFAULT , @Path);
	SET @Template = REPLACE(@Template,'@(Filename)' COLLATE DATABASE_DEFAULT , @Filename);

	IF (@Debug = 1) PRINT @Template
	EXEC (@Template)
;

END
GO
