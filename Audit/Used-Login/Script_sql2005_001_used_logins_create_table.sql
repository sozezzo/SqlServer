use msdb
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
Go
CREATE SCHEMA [Monitor];
GO
GO
CREATE TABLE [Monitor].[UsedLogin](
	[UsedLoginId] [int] IDENTITY(1,1) NOT NULL,
	[MonitorLocalDate] [INT] NOT NULL,
	[LoginName] [nvarchar](128) NULL,
	[HostName] [nvarchar](256) NULL,
	[DatabaseName] [nvarchar](50) NULL,
	[ProgramName] [nvarchar](128) NULL,
	[LastBatch] [datetime] NULL,
 CONSTRAINT [PK_UsedLogin] PRIMARY KEY CLUSTERED 
(
	[UsedLoginId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
GO

