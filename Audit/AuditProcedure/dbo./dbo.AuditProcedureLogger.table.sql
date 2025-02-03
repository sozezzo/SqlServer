SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[AuditProcedureLogger](
	[AuditProcedureLogger_ID] [int] IDENTITY(1,1) NOT NULL,
	[event_date] [datetime] NOT NULL,
	[AuditProcedureMetadata_id] [int] NOT NULL,
	[parameters] [nvarchar](max) NULL,
PRIMARY KEY CLUSTERED 
(
	[AuditProcedureLogger_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[AuditProcedureLogger]  WITH CHECK ADD  CONSTRAINT [FK_AuditProcedureLogger_Metadata] FOREIGN KEY([AuditProcedureMetadata_id])
REFERENCES [dbo].[AuditProcedureMetadata] ([AuditProcedureMetadata_id])
ON DELETE CASCADE
GO

ALTER TABLE [dbo].[AuditProcedureLogger] CHECK CONSTRAINT [FK_AuditProcedureLogger_Metadata]
GO


