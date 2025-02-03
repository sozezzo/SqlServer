

``` sql
create procedure #AuditProcedureCode 
(
	@SchemaName NVARCHAR(128) ,
	@ProcedureName NVARCHAR(128)  
)
as
begin

	DECLARE @AuditCode NVARCHAR(MAX);
	DECLARE @ParamList NVARCHAR(MAX) = '';

	-- Get all parameters of the stored procedure
	SELECT @ParamList = @ParamList + ', ' + name + ' AS [' + name + ']'
	FROM sys.parameters 
	WHERE object_id = OBJECT_ID(@SchemaName + '.' + @ProcedureName)
	ORDER BY parameter_id;

	-- Remove leading comma and space
	SET @ParamList = STUFF(@ParamList, 1, 2, '');

	-- Generate the audit logging block
	SET @AuditCode = '
	-- -- -- -- -- -- -- -- -- 
	--#region Audit Used Stored Procedure
	SET NOCOUNT ON;
	DECLARE @ObjectParameter NVARCHAR(MAX) = '''';
	SET @ObjectParameter = (SELECT ' + @ParamList + ' FOR XML PATH(''p''));
	EXEC [usp_AuditProcedureLogger] @PROCID=@@PROCID, @ObjectParameter=@ObjectParameter;
	--#endregion Audit Used Stored Procedure
	-- -- -- -- -- -- -- -- -- 
	';

	-- Print or execute the result
	PRINT @AuditCode;
end
go
```
