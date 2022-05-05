USE [master]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
 *        Name: [dbo].[sp_FailoverJob]
 *
 * Description: Manipulate status jobs to follow server failover 
 *
 *
 */
CREATE OR ALTER PROCEDURE [dbo].[sp_FailoverJob] 
(
   @Categoryname AS NVARCHAR(100)
) AS
BEGIN

	SET NOCOUNT ON

	DECLARE @newStatus AS NVARCHAR(1) = '0';
	DECLARE @JobName   AS NVARCHAR(255);
	DECLARE @sqlEnable AS NVARCHAR(max);
	DECLARE @sql       AS NVARCHAR(max);
	DECLARE @isEnabled AS NVARCHAR(1);

	SELECT @newStatus = 1 
	--   select master.sys.availability_groups.name AS Name, master.sys.availability_replicas.replica_server_name, ISNULL(master.sys.dm_hadr_availability_replica_states.role, 3) AS LocalReplicaRole
	FROM master.sys.availability_groups
	INNER JOIN master.sys.availability_replicas ON master.sys.availability_groups.group_id = master.sys.availability_replicas.group_id
	INNER JOIN master.sys.dm_hadr_availability_replica_states ON master.sys.availability_replicas.replica_id = master.sys.dm_hadr_availability_replica_states.replica_id
	WHERE master.sys.availability_replicas.replica_server_name = @@servername AND master.sys.dm_hadr_availability_replica_states.ROLE = 1;

	SET @sql = 'EXEC msdb.dbo.sp_update_job @job_name = N''${JobName}'', @enabled = ' + @newStatus + ';'

	SELECT replace(@sql, '${JobName}', sysjobs.NAME) AS sqlEnable
		, sysjobs.NAME AS JobName
		, job_id
		, [enabled] isEnabled
	INTO #jobs
	-- SELECT sysjobs.name 'Job Name' , job_id, [enabled] isEnabled, syscategories.name
	FROM msdb.dbo.sysjobs
	INNER JOIN msdb.dbo.syscategories ON msdb.dbo.sysjobs.category_id = msdb.dbo.syscategories.category_id
	WHERE syscategories.NAME = @Categoryname AND NOT ([enabled] = @newStatus)

	WHILE ( EXISTS ( SELECT JobName FROM #jobs ) )
	BEGIN

		SELECT TOP 1 
			 @JobName   = JobName
			,@sqlEnable = sqlEnable
			,@isEnabled = isEnabled
		FROM #jobs;

		DELETE
		FROM #jobs
		WHERE JobName = @JobName;
		--print @sqlEnable;
		EXEC (@sqlEnable)

		IF (@JobName = 'Automatic Failover Synchronization')
		BEGIN
			BEGIN TRY
			EXEC msdb.dbo.sp_start_job @job_name=N'Automatic Failover Synchronization'
			END TRY
			BEGIN CATCH
			END CATCH
		END

		-- SEND WARNING
		DECLARE @subject AS NVARCHAR(MAX) = 'Job ['+@JobName+'] is ' +CASE WHEN @isEnabled = '0' THEN 'ENABLE' ELSE 'DISABLE' END;
		DECLARE @body   AS NVARCHAR(MAX) = '
Server name : ' + @@servername +'

Category name : ['+@Categoryname+']

Job Name : [' + @JobName + ']  

Script Sql : 

'+@sqlEnable+'



*sent by msdb.dbo.sp_FailoverJob
	
	';
		--EXEC msdb.dbo.sp_send_dbmail
		--	@profile_name	= N'Notification',
		--	@recipients		= 'email@domain.com;',
		--	--@copy_recipients= @recipientsCC,
		--	@subject		= @subject,
		--	@body			= @body,
		--	@importance     = 'LOW'
	
	END

END -- end begin procedure


