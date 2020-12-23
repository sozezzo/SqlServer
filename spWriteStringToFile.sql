/*
*  Name : #spWriteStringToFile
*  Description : Write in text file
*
*  Syntax :
*  EXEC #spWriteStringToFile @String = 'Hello Word!', @Path = 'C:\Temp\', @Filename = 'myfile.txt';
*
*  Info : OA procs can only be accessed with Sysadmin authority
*
*/
CREATE OR ALTER PROCEDURE #spWriteStringToFile
( @String VARCHAR(MAX)
, @Path VARCHAR(512)
, @Filename VARCHAR(512)
)
AS
BEGIN
/*
-- Set configuration to use Ole Automation Procedures
GO
exec sp_configure 'show advanced options', 1 
GO 
RECONFIGURE; 
GO 
exec sp_configure 'Ole Automation Procedures', 1 
GO 
RECONFIGURE; 
GO 
exec sp_configure 'show advanced options', 1 
GO 
RECONFIGURE;
GO
*/
	SET NOCOUNT ON;

	DECLARE @objFileSystem INT , @objTextStream INT , @objErrorObject INT , @strErrorMessage VARCHAR(1000) , @Command VARCHAR(1000) , @hr INT , @fileAndPath VARCHAR(512);
	SET NOCOUNT ON;
	SELECT @strErrorMessage = 'opening the File System Object';
	EXECUTE @hr = sp_OACreate 'Scripting.FileSystemObject'
	,                         @objFileSystem OUT;

	SELECT @FileAndPath = @path + '\' COLLATE DATABASE_DEFAULT + @filename;

	IF @HR = 0
		SELECT @objErrorObject = @objFileSystem
		,      @strErrorMessage = 'Creating file "' COLLATE DATABASE_DEFAULT + @FileAndPath + '"' COLLATE DATABASE_DEFAULT ;
	IF @HR = 0
		EXECUTE @hr = sp_OAMethod @objFileSystem
		,                         'CreateTextFile'
		,                         @objTextStream OUT
		,                         @FileAndPath
		,                         2
		,                         True;
	IF @HR = 0
		SELECT @objErrorObject = @objTextStream
		,      @strErrorMessage = 'writing to the file "' COLLATE DATABASE_DEFAULT + @FileAndPath + '"' COLLATE DATABASE_DEFAULT ;
	IF @HR = 0
		EXECUTE @hr = sp_OAMethod @objTextStream
		,                         'Write'
		,                         NULL
		,                         @String;
	IF @HR = 0
		SELECT @objErrorObject = @objTextStream
		,      @strErrorMessage = 'closing the file "' COLLATE DATABASE_DEFAULT + @FileAndPath + '"' COLLATE DATABASE_DEFAULT ;
	IF @HR = 0
		EXECUTE @hr = sp_OAMethod @objTextStream
		,                         'Close';
	IF @hr <> 0
	BEGIN
		DECLARE @Source VARCHAR(255) , @Description VARCHAR(255) , @Helpfile VARCHAR(255) , @HelpID INT;
		EXECUTE sp_OAGetErrorInfo @objErrorObject
		,                         @source OUTPUT
		,                         @Description OUTPUT
		,                         @Helpfile OUTPUT
		,                         @HelpID OUTPUT;
		SELECT @strErrorMessage = 'Error whilst ' + COALESCE(@strErrorMessage, 'doing something' COLLATE DATABASE_DEFAULT ) + ', ' COLLATE DATABASE_DEFAULT + COALESCE(@Description, '' COLLATE DATABASE_DEFAULT );
		RAISERROR(@strErrorMessage, 16, 1);
	END;
	EXECUTE sp_OADestroy @objTextStream;
	EXECUTE sp_OADestroy @objFileSystem;
END;
