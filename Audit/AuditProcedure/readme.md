Exemple to use:

We have this procedure:
``` sql

CREATE Procedure [dbo].[sp_test]
@Sector_id Int, @Starttime Int, @Endtime Int  
AS
begin
	select @Sector_id, @Starttime, @Endtime
end

```


For this example, you need to add this code to logger the call of stroed procedure.
``` sql
 -- -- -- -- -- -- -- -- -- 
	--#region Audit Used Stored Procedure
	SET NOCOUNT ON;
	DECLARE @ObjectParameter NVARCHAR(MAX) = '';
	SET @ObjectParameter = (SELECT @Sector_id AS [@Sector_id], @Starttime AS [@Starttime], @Endtime AS [@Endtime] FOR XML PATH('p'));
	EXEC [usp_AuditProcedureLogger] @PROCID=@@PROCID, @ObjectParameter=@ObjectParameter;
	--#endregion Audit Used Stored Procedure
	-- -- -- -- -- -- -- -- --
```

This is the result:
``` sql
create Procedure [dbo].[sp_test]
@Sector_id Int, @Starttime Int, @Endtime Int  
AS
begin

	-- -- -- -- -- -- -- -- -- 
	--#region Audit Used Stored Procedure
	SET NOCOUNT ON;
	DECLARE @ObjectParameter NVARCHAR(MAX) = '';
	SET @ObjectParameter = (SELECT @Sector_id AS [@Sector_id], @Starttime AS [@Starttime], @Endtime AS [@Endtime] FOR XML PATH('p'));
	EXEC [usp_AuditProcedureLogger] @PROCID=@@PROCID, @ObjectParameter=@ObjectParameter;
	--#endregion Audit Used Stored Procedure
	-- -- -- -- -- -- -- -- -- 

	select @Sector_id, @Starttime, @Endtime
end
```

If we have just 1 or 2 stored procedure, It's ease to modifify and adapt to the stored procedure we want to logger, but if we have many stored procedures, maybe, we can create the code using the temporary procedure #AuditProcedureCode.

We just need the schema and procedure name.

``` sql
exec #AuditProcedureCode 'dbo', 'sp_test'

```



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
