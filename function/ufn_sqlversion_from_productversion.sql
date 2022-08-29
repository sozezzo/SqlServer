SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER FUNCTION dbo.ufn_sqlversion_from_productversion
(
	@productversion varchar(10) 
)
RETURNS varchar(10) 
AS
BEGIN

if (isnull(@productversion, '') = '')
SET @productversion = CAST(SERVERPROPERTY ('productversion') as VARCHAR(10));

DECLARE @version varchar(10);
SELECT @version =
  CASE 
     WHEN CONVERT(VARCHAR(128), @productversion) like '8%' THEN 'SQL2000'
     WHEN CONVERT(VARCHAR(128), @productversion) like '9%' THEN 'SQL2005'
     WHEN CONVERT(VARCHAR(128), @productversion) like '10.0%' THEN 'SQL2008'
     WHEN CONVERT(VARCHAR(128), @productversion) like '10.5%' THEN 'SQL2008R2'
     WHEN CONVERT(VARCHAR(128), @productversion) like '11%' THEN 'SQL2012'
     WHEN CONVERT(VARCHAR(128), @productversion) like '12%' THEN 'SQL2014'
     WHEN CONVERT(VARCHAR(128), @productversion) like '13%' THEN 'SQL2016'     
     WHEN CONVERT(VARCHAR(128), @productversion) like '14%' THEN 'SQL2017' 
     WHEN CONVERT(VARCHAR(128), @productversion) like '15%' THEN 'SQL2019' 
     WHEN CONVERT(VARCHAR(128), @productversion) like '16%' THEN 'SQL2022' 
     ELSE 'unknown' END

return @version

END
GO

--  print dbo.ufn_sqlversion_from_productversion(11)
--  print dbo.ufn_sqlversion_from_productversion(null)
