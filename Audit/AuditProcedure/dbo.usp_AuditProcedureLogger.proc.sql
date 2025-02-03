SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_AuditProcedureLogger]
(
    @PROCID INT = NULL,
    @schema_name NVARCHAR(100) = NULL,  
    @object_name NVARCHAR(128) = NULL,
    @ObjectParameter NVARCHAR(MAX) = NULL,
	@event_date DATETIME = NULL
)
AS
BEGIN

    SET NOCOUNT ON;
    DECLARE @AuditProcedureMetadata_id INT;

    BEGIN TRY
        -- Resolve procedure name if PROCID is provided
        IF (@PROCID IS NOT NULL)
        BEGIN
            SELECT @schema_name = OBJECT_SCHEMA_NAME(@PROCID),
                   @object_name = OBJECT_NAME(@PROCID);
        END

        -- Ensure valid schema and object names
        IF (@schema_name IS NULL OR @object_name IS NULL)
        BEGIN
            PRINT 'Schema or Object name is NULL. Aborting logging.';
            RETURN;
        END

        -- Default empty string for @ObjectParameter if NULL
        IF (@ObjectParameter IS NULL)
            SET @ObjectParameter = '';

        -- Check if metadata already exists
        SELECT @AuditProcedureMetadata_id = AuditProcedureMetadata_id 
        FROM AuditProcedureMetadata
        WHERE original_user = ORIGINAL_LOGIN()
          AND host_name = HOST_NAME()
          AND application_name = APP_NAME()
          AND schema_name = @schema_name
          AND object_name = @object_name;

        -- Insert new metadata entry if not found
        IF @AuditProcedureMetadata_id IS NULL
        BEGIN
            INSERT INTO AuditProcedureMetadata (original_user, host_name, application_name, schema_name, object_name)
            VALUES (ORIGINAL_LOGIN(), HOST_NAME(), APP_NAME(), @schema_name, @object_name);

            SET @AuditProcedureMetadata_id = SCOPE_IDENTITY();
        END

        -- Insert log entry
        INSERT INTO AuditProcedureLogger (event_date, AuditProcedureMetadata_id, parameters)
        VALUES (isnull(@event_date,getutcdate()), @AuditProcedureMetadata_id, @ObjectParameter);

    END TRY
    BEGIN CATCH
        PRINT 'Error in uspAuditProcedureLogger: ' + ERROR_MESSAGE();
    END CATCH;
END
GO


