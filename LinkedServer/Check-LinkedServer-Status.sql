-- it identifies the linked servers, and verifies that they still work.

SET NOCOUNT ON;
DROP TABLE IF EXISTS #LinkedServers;
SELECT * INTO #LinkedServers from [sys].[servers];

DROP TABLE IF EXISTS #LinkedServersStatus;
CREATE TABLE #LinkedServersStatus (server_id int, [name] sysname, [Status] int, [StatusDescription] varchar(128));
DECLARE @retval int = 0, @sysservername sysname;

DECLARE @server_id INT = 0;
WHILE ((SELECT COUNT(*) FROM #LinkedServers) > 0)
BEGIN

  SELECT TOP 1 @server_id = server_id, @sysservername = CONVERT(sysname, [name]) FROM #LinkedServers ORDER BY server_id ASC;
	DELETE FROM #LinkedServers WHERE @server_id = server_id;

	BEGIN TRY
		EXEC @retval = sys.sp_testlinkedserver @sysservername;
		INSERT INTO #LinkedServersStatus (server_id, [name], [Status], [StatusDescription])
		VALUES (@server_id, @sysservername, 1, 'OK');
	END TRY
	BEGIN CATCH
		INSERT INTO #LinkedServersStatus (server_id, [name], [Status], [StatusDescription])
		VALUES (@server_id, @sysservername, 0, 'FAIL');
	END CATCH;      

END
SELECT @@servername as 'ServerName', GetUtcdate() as DateUtc, server_id, [name] as LinkedServerName, [Status], [StatusDescription] FROM #LinkedServersStatus;
GO
