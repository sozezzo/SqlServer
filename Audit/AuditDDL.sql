SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[AuditDDL](
	[AuditDDL_ID] [int] IDENTITY(1,1) NOT NULL,
	[Event_Type] [varchar](100) NULL,
	[Database_Name] [varchar](100) NULL,
	[SchemaName] [varchar](100) NULL,
	[ObjectName] [varchar](100) NULL,
	[ObjectType] [varchar](100) NULL,
	[EventDate] [datetime] NULL,
	[SystemUser] [varchar](100) NULL,
	[CurrentUser] [varchar](100) NULL,
	[HostName] [varchar](100) NULL,
	[OriginalUser] [varchar](100) NULL,
	[EventDataText] [varchar](max) NULL,
 CONSTRAINT [pk_AuditDDL] PRIMARY KEY CLUSTERED 
(
	[AuditDDL_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 98, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO


GO
--
-- Name: tr_AuditDDL_MonitorChange
-- Description: Generate audit traces.
--         url: http://schottsql.blogspot.com/2010/02/ddl-schema-change-auditing-on-sql.html
--
CREATE OR ALTER TRIGGER [tr_AuditDDL_MonitorChange] 
      ON DATABASE FOR DDL_DATABASE_LEVEL_EVENTS
AS

SET NOCOUNT ON
SET ANSI_PADDING ON
declare @EventType varchar(100)
declare @SchemaName varchar(100)
declare @DatabaseName varchar(100)
declare @ObjectName varchar(100)
declare @ObjectType varchar(100)
DECLARE @EventDataText VARCHAR(MAX)
BEGIN TRY

SELECT 
    @EventType    =EVENTDATA().value('(/EVENT_INSTANCE/EventType)[1]','nvarchar(max)')   ,
    @DatabaseName =EVENTDATA().value('(/EVENT_INSTANCE/DatabaseName)[1]','nvarchar(max)'),
    @SchemaName   =EVENTDATA().value('(/EVENT_INSTANCE/SchemaName)[1]','nvarchar(max)')  ,
    @ObjectName   =EVENTDATA().value('(/EVENT_INSTANCE/ObjectName)[1]','nvarchar(max)')  ,
    @ObjectType   =EVENTDATA().value('(/EVENT_INSTANCE/ObjectType)[1]','nvarchar(max)')  ,
    @EventDataText=EVENTDATA().value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]','nvarchar(max)')


--------------------
-- Add Exceptions --
-- ex.:

-- if ( @ObjectName = 'MyTable_DONT_be_watched') return
-- if ( @EventType = 'UPDATE_STATISTICS' ) return

--------------------


INSERT INTO AuditDDL
	(
	Event_Type,Database_Name,SchemaName,ObjectName ,
	ObjectType,EventDate    ,SystemUser,CurrentUser,
	HostName  ,OriginalUser ,EventDataText
	)
SELECT 
    @EventType,@DatabaseName,@SchemaName  ,@ObjectName ,
    @ObjectType  ,GETDATE()    ,SUSER_SNAME(),CURRENT_USER,
    HOST_NAME()  ,ORIGINAL_LOGIN(), @EventDataText

---- Clean-up
DELETE FROM AuditDDL WHERE AuditDDL_ID IN
(
    SELECT MIN(AuditDDL_ID) AS AuditDDL_ID
    FROM AuditDDL AS ToDelete
    WHERE EventDate < DateAdd(y,-1, GetDate())
    GROUP BY Database_Name, SchemaName, ObjectName, ObjectType
    HAVING(COUNT(*)>100)
)
END TRY
BEGIN CATCH
END CATCH
GO

ENABLE TRIGGER [tr_AuditDDL_MonitorChange] ON DATABASE
GO

