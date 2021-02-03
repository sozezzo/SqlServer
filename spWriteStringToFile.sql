CREATE OR ALTER PROCEDURE #spWriteStringToFile
/*
*  Name : #spWriteStringToFile
*  Description : Write in text file
*
*  Syntax :
*  EXEC #spWriteStringToFile @Text = 'Hello Word!', @File = 'C:\Temp\myfile.txt';
*
*  Info : OA procs can only be accessed with Sysadmin authority
*
*/
(
  @File NVARCHAR(4000),
  @Text NVARCHAR(MAX),
  @Charset NVARCHAR(100) = 'UTF-8'
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

	DECLARE @OLE            INT 

	EXECUTE sp_OACreate 'ADODB.Stream',  @OLE OUTPUT

	EXECUTE sp_OASetProperty             @OLE,    'Type',             2                           --1 = binary, 2 = text
	EXECUTE sp_OASetProperty             @OLE,    'Mode',             3                           --0 = not set, 1 read, 2 write, 3 read/write
	EXECUTE sp_OASetProperty             @OLE,    'Charset',          @Charset                     
	EXECUTE sp_OASetProperty             @OLE,    'LineSeparator',    'adLF'
	EXECUTE sp_OAMethod                  @OLE,    'Open'  
	EXECUTE sp_OAMethod                  @OLE,    'WriteText',        NULL,       @Text      --text method

	--Commit data and close text stream
	EXECUTE sp_OAMethod                  @OLE,    'SaveToFile',       NULL,       @File, 2   --1 = notexist 2 = overwrite
	EXECUTE sp_OAMethod                  @OLE,    'Close'
	EXECUTE sp_OADestroy                 @OLE

	EXECUTE sp_OADestroy @OLE 

END 
GO
