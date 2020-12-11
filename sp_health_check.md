Health Check 

Quickly outlines key facts about the status and specs of a Microsoft SQL Server which gives a starting point to address current and potential issues.

Despite the fact that there are multiple queries executed by the stored procedure, the data in question is mainly retrieved from memory, so it is safe to be run in production. It contains a waitfor delay, which extends the elapsed time. Try it first on a testing environment.

The stored procedure is a compound of scripts that were not only created by me; more specifically, there’s code from (in order of appearance):

Vishal Gajjar’s (@SqlAndMe) “Get SQL Server Service Account using T-SQL” to retrive service account details on old versions

Basit A. Farooq’s (@BasitAali) “Get SQL Server Physical Cores, Physical and Virtual CPUs, and Processor type information using Transact-SQL (T-SQL) script” to obtain CPU specs

Benjamin Nevarez’s (@BenjaminNevarez) “Getting CPU Utilization Data from SQL Server” to retrieve CPU use from sys.dm_os_ring_buffers

Paul Randall’s (@PaulRandal) “Wait statistics, or please tell me where it hurts” to pull information around wait statistics

Ryan DeVries (@RJ_DeVries) to get the last good DBCC CHECK in all databases

And although I did the rest, I stand on the shoulders of giants such as Jonathan Kehayias, Paul Randall, Benjamin Nevarez, Aaron Bertrand, Kendra Little, David Klee, Kevin Kline, and other authors to whom I owe a lot of what I know.

#sp_health_check is functional on all recent versions of SQL Server, and will display more useful information on versions starting from 2008 R2 SP1.

The login executing #sp_health_check requires sysadmin privileges.

The stored procedure uses the extended stored procedure xp_cmdshell to query the Windows WMIC when the data is unavailable on dynamic management views on old versions.

A list of what the script checks is being put together and will be published shortly.