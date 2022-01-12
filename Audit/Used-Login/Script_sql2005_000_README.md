
Audit used logins ( but Keep it simple)

**This script was created to run on SQL2005.**

The purpose is to know: 
Who access? What database? From where? With what application? ... each day ...

``` sql

SELECT  UsedLoginId, MonitorLocalDate, LoginName, HostName
        DatabaseName, ProgramName, LastBatch 
FROM msdb.Monitor.UsedLogin

```

``` sql

SELECT  DISTINCT LoginName, HostName, DatabaseName 
FROM msdb.Monitor.UsedLogin

```

This script uses [msdb], and create a job to monitoring.


Nice solutions:

SQL Server Security Audit Basics
https://www.red-gate.com/simple-talk/databases/sql-server/database-administration-sql-server/sql-server-security-audit-basics/


SQL Server - How to implement audit and control of logins (Logon Trigger)
https://en.dirceuresende.com/blog/como-implementar-auditoria-e-controle-de-logins-no-sql-server-trigger-logon/


Security: Create and view Audit Logs
https://www.sqlservercentral.com/blogs/security-create-and-view-audit-logs