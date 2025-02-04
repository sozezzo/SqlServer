SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[AuditProcedureMetadata](
	[AuditProcedureMetadata_id] [int] IDENTITY(1,1) NOT NULL,
	[original_user] [varchar](128) NOT NULL,
	[host_name] [varchar](128) NULL,
	[application_name] [varchar](128) NOT NULL,
	[schema_name] [varchar](100) NOT NULL,
	[object_name] [varchar](128) NOT NULL,
	[created_date] [datetime] NULL,
 CONSTRAINT [PK__AuditPro__1D1DCD0D7AD3CAFD] PRIMARY KEY CLUSTERED 
(
	[AuditProcedureMetadata_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_AuditProcedureMetadata] UNIQUE NONCLUSTERED 
(
	[original_user] ASC,
	[host_name] ASC,
	[application_name] ASC,
	[schema_name] ASC,
	[object_name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[AuditProcedureMetadata] ADD  CONSTRAINT [DF_AuditProcedureMetadata_created_date]  DEFAULT (getutcdate()) FOR [created_date]
GO

