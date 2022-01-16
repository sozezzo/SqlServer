-- it identifies the linked servers, and verifies that they still work.

SET NOCOUNT ON;
drop table if exists #tbLinkedServer
go

SET NOCOUNT ON;

DECLARE @tb table (CATALOG_NAME nvarchar(128), [DESCRIPTION] nvarchar(255));
DECLARE @retval int = 0;
DECLARE @linked_server_name sysname;
DECLARE @sql nvarchar(max);

select
	getutcdate() as [time],
	@@servername as server_name,
    srv.name as linked_server_name,
    srv.data_source,
	-1 as [status],
	cast('' as nvarchar(1024)) as [status_desc]
into #tbLinkedServer
from
    sys.servers srv
where is_linked = 1;

while ((select count(*) from #tbLinkedServer where [status] = -1) > 0)
begin

	select @linked_server_name = linked_server_name  from #tbLinkedServer where [status] = -1;
	BEGIN TRY
		EXEC @retval = sys.sp_testlinkedserver @linked_server_name;
		SET @sql = 'exec sp_catalogs @server_name = '''+@linked_server_name+''';'
		INSERT INTO @tb EXEC (@sql);
		update #tbLinkedServer set [status] = 1, [status_desc] = 'OK' where  linked_server_name = @linked_server_name
	END TRY
	BEGIN CATCH
		update #tbLinkedServer set [status] = 0, [status_desc] = ERROR_MESSAGE() where  linked_server_name = @linked_server_name
	END CATCH; 

end

select [time], server_name, linked_server_name, data_source, [status], [status_desc] from #tbLinkedServer;

