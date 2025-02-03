SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[vw_AuditProcedureLogger]
as
SELECT 
    AuditProcedureLogger.AuditProcedureLogger_ID, 
    AuditProcedureLogger.event_date, 
    AuditProcedureMetadata.original_user, 
    AuditProcedureMetadata.host_name, 
    AuditProcedureMetadata.application_name, 
    AuditProcedureMetadata.schema_name, 
    AuditProcedureMetadata.object_name, 
    AuditProcedureLogger.parameters
FROM 
    AuditProcedureLogger 
INNER JOIN 
    AuditProcedureMetadata 
ON 
    AuditProcedureLogger.AuditProcedureMetadata_ID = AuditProcedureMetadata.AuditProcedureMetadata_ID;
GO

