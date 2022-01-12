use msdb
GO
DROP PROCEDURE [Monitor].[uspUsedLogin];
GO
/*
 * Description: Log used logins
 */
CREATE PROCEDURE [Monitor].[uspUsedLogin]
AS
BEGIN

	SET nocount ON

	SELECT convert(INT , convert(varchar, getdate(), 112)) AS [MonitorLocalDate]
	,      CAST(ISNULL(CONVERT(sysname, rtrim(loginame)),'') AS [nvarchar](128)) AS [LoginName]
	,      CAST(HostName as [nvarchar](256)) AS HostName
	,      CASE WHEN dbid=0 THEN '' ELSE db_name(dbid) END AS [DatabaseName]
	,      CAST(program_name AS [nvarchar](128)) AS ProgramName
	,      MAX(last_batch) AS LastBatch
	INTO #sysprocesses
	FROM sys.sysprocesses WITH (nolock)
	GROUP BY CONVERT(sysname, rtrim(loginame))
	,        HostName
	,        program_name
	,        dbid
	
	UPDATE [Monitor].[UsedLogin] 
	SET LastBatch = s.LastBatch
	FROM #sysprocesses s INNER JOIN [Monitor].[UsedLogin] t ON
	    s.[MonitorLocalDate] = t.[MonitorLocalDate]
	AND s.[LoginName] = t.[LoginName]
	AND s.[HostName] = t.[HostName]
	AND s.[DatabaseName] = t.[DatabaseName]
	AND s.[ProgramName] = t.[ProgramName]
	AND s.LastBatch <> t.LastBatch 

	INSERT INTO [Monitor].[UsedLogin] 
	     (   [MonitorLocalDate] ,   [LoginName],   HostName,  DatabaseName,  ProgramName ,   LastBatch )
	SELECT s.[MonitorLocalDate] , s.[LoginName], s.HostName,s.DatabaseName,s.ProgramName , s.LastBatch
	FROM #sysprocesses s LEFT OUTER JOIN [Monitor].[UsedLogin] t ON
	    s.[MonitorLocalDate] = t.[MonitorLocalDate]
	AND s.[LoginName] = t.[LoginName]
	AND s.[HostName] = t.[HostName]
	AND s.[DatabaseName] = t.[DatabaseName]
	AND s.[ProgramName] = t.[ProgramName]
	WHERE t.[UsedLoginId] IS NULL

END
GO
---
