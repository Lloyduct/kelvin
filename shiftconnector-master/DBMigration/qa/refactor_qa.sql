-- Setting COMPATIBILITY to 2019
ALTER DATABASE combitReportServer SET COMPATIBILITY_LEVEL = 150 
ALTER DATABASE shiftconnector_CAO_CPU SET COMPATIBILITY_LEVEL = 150 
ALTER DATABASE shiftconnector_CAO_HDI SET COMPATIBILITY_LEVEL = 150 
ALTER DATABASE shiftconnector_CAO_MDI SET COMPATIBILITY_LEVEL = 150 
ALTER DATABASE shiftconnector_CAO_MDI1 SET COMPATIBILITY_LEVEL = 150 
ALTER DATABASE shiftconnector_CAO_NIU SET COMPATIBILITY_LEVEL = 150 
ALTER DATABASE shiftconnector_CAO_PIC_PUD SET COMPATIBILITY_LEVEL = 150 
ALTER DATABASE shiftconnector_CAO_TDI1 SET COMPATIBILITY_LEVEL = 150 
ALTER DATABASE shiftconnector_CAO_TDI2 SET COMPATIBILITY_LEVEL = 150 
ALTER DATABASE shiftconnector_gsi SET COMPATIBILITY_LEVEL = 150 
ALTER DATABASE shiftconnector_GUA_CCDC SET COMPATIBILITY_LEVEL = 150 
ALTER DATABASE shiftconnector712_dashboards SET COMPATIBILITY_LEVEL = 150 
ALTER DATABASE shiftconnector712_test SET COMPATIBILITY_LEVEL = 150 
ALTER DATABASE shiftconnector75_legacy SET COMPATIBILITY_LEVEL = 150 
ALTER DATABASE shiftconnector75_test SET COMPATIBILITY_LEVEL = 150 
ALTER DATABASE shiftconnector79_test2 SET COMPATIBILITY_LEVEL = 150 


DBCC UPDATEUSAGE('combitReportServer') WITH COUNT_ROWS
DBCC UPDATEUSAGE('shiftconnector_CAO_CPU') WITH COUNT_ROWS
DBCC UPDATEUSAGE('shiftconnector_CAO_HDI') WITH COUNT_ROWS
DBCC UPDATEUSAGE('shiftconnector_CAO_MDI') WITH COUNT_ROWS
DBCC UPDATEUSAGE('shiftconnector_CAO_MDI1') WITH COUNT_ROWS
DBCC UPDATEUSAGE('shiftconnector_CAO_NIU') WITH COUNT_ROWS
DBCC UPDATEUSAGE('shiftconnector_CAO_PIC_PUD') WITH COUNT_ROWS
DBCC UPDATEUSAGE('shiftconnector_CAO_TDI1') WITH COUNT_ROWS
DBCC UPDATEUSAGE('shiftconnector_CAO_TDI2') WITH COUNT_ROWS
DBCC UPDATEUSAGE('shiftconnector_gsi') WITH COUNT_ROWS
DBCC UPDATEUSAGE('shiftconnector_GUA_CCDC') WITH COUNT_ROWS
DBCC UPDATEUSAGE('shiftconnector712_dashboards') WITH COUNT_ROWS
DBCC UPDATEUSAGE('shiftconnector712_test') WITH COUNT_ROWS
DBCC UPDATEUSAGE('shiftconnector75_legacy') WITH COUNT_ROWS
DBCC UPDATEUSAGE('shiftconnector75_test') WITH COUNT_ROWS
DBCC UPDATEUSAGE('shiftconnector79_test2') WITH COUNT_ROWS




USE [master]
--- 
-- Rebuild Indexes (takes approx 1 hour)
DECLARE @Database NVARCHAR(255)   
DECLARE @Table NVARCHAR(255)  
DECLARE @cmd NVARCHAR(1000)  

DECLARE DatabaseCursor CURSOR READ_ONLY FOR  
SELECT name FROM master.sys.databases   
WHERE name NOT IN ('master','msdb','tempdb','model','distribution','rdsadmin')  -- databases to exclude
--WHERE name IN ('shiftconnector_CAO_CPU') -- use this to select specific databases and comment out line above
AND state = 0 -- database is online
AND is_in_standby = 0 -- database is not read only for log shipping
ORDER BY 1  

OPEN DatabaseCursor  

FETCH NEXT FROM DatabaseCursor INTO @Database  
WHILE @@FETCH_STATUS = 0  
BEGIN  

   SET @cmd = 'DECLARE TableCursor CURSOR READ_ONLY FOR SELECT ''['' + table_catalog + ''].['' + table_schema + ''].['' +  
   table_name + '']'' as tableName FROM [' + @Database + '].INFORMATION_SCHEMA.TABLES WHERE table_type = ''BASE TABLE'''   

   -- create table cursor  
   EXEC (@cmd)  
   OPEN TableCursor   
   PRINT '---'
   PRINT @Database 
   PRINT '---'
   FETCH NEXT FROM TableCursor INTO @Table   
   WHILE @@FETCH_STATUS = 0   
   BEGIN
      BEGIN TRY   
         SET @cmd = 'ALTER INDEX ALL ON ' + @Table + ' REBUILD' 
         PRINT @cmd -- uncomment if you want to see commands
         EXEC (@cmd) 
      END TRY
      BEGIN CATCH
         PRINT '---'
         PRINT @cmd
         PRINT ERROR_MESSAGE() 
         PRINT '---'
      END CATCH

      FETCH NEXT FROM TableCursor INTO @Table   
   END   

   CLOSE TableCursor   
   DEALLOCATE TableCursor  

   FETCH NEXT FROM DatabaseCursor INTO @Database  
END  
CLOSE DatabaseCursor   
DEALLOCATE DatabaseCursor





USE combitReportServer

DECLARE @csql nvarchar(MAX);
SELECT @csql = ( SELECT ' UPDATE STATISTICS ' +
quotename(s.name) + '.' + quotename(o.name) +
' WITH FULLSCAN; ' + CHAR(13) AS [text()]
  FROM sys.objects o
  JOIN sys.schemas s ON o.schema_id = s.schema_id
  WHERE o.type = 'U'
  FOR XML PATH(''), TYPE).value('.', 'nvarchar(MAX)');
PRINT @csql
 EXEC (@csql)


USE shiftconnector_CAO_CPU

DECLARE @csql nvarchar(MAX);
SELECT @csql = ( SELECT ' UPDATE STATISTICS ' +
quotename(s.name) + '.' + quotename(o.name) +
' WITH FULLSCAN; ' + CHAR(13) AS [text()]
  FROM  sys.objects o
  JOIN  sys.schemas s ON o.schema_id = s.schema_id
  WHERE  o.type = 'U'
  FOR XML PATH(''), TYPE).value('.', 'nvarchar(MAX)');
PRINT @csql
 EXEC (@csql)
USE shiftconnector_CAO_HDI

DECLARE @csql nvarchar(MAX);
SELECT @csql = ( SELECT ' UPDATE STATISTICS ' +
quotename(s.name) + '.' + quotename(o.name) +
' WITH FULLSCAN; ' + CHAR(13) AS [text()]
  FROM  sys.objects o
  JOIN  sys.schemas s ON o.schema_id = s.schema_id
  WHERE  o.type = 'U'
  FOR XML PATH(''), TYPE).value('.', 'nvarchar(MAX)');
PRINT @csql
 EXEC (@csql)
USE shiftconnector_CAO_MDI

DECLARE @csql nvarchar(MAX);
SELECT @csql = ( SELECT ' UPDATE STATISTICS ' +
quotename(s.name) + '.' + quotename(o.name) +
' WITH FULLSCAN; ' + CHAR(13) AS [text()]
  FROM  sys.objects o
  JOIN  sys.schemas s ON o.schema_id = s.schema_id
  WHERE  o.type = 'U'
  FOR XML PATH(''), TYPE).value('.', 'nvarchar(MAX)');
PRINT @csql
 EXEC (@csql)
USE shiftconnector_CAO_MDI1

DECLARE @csql nvarchar(MAX);
SELECT @csql = ( SELECT ' UPDATE STATISTICS ' +
quotename(s.name) + '.' + quotename(o.name) +
' WITH FULLSCAN; ' + CHAR(13) AS [text()]
  FROM  sys.objects o
  JOIN  sys.schemas s ON o.schema_id = s.schema_id
  WHERE  o.type = 'U'
  FOR XML PATH(''), TYPE).value('.', 'nvarchar(MAX)');
PRINT @csql
 EXEC (@csql)
USE shiftconnector_CAO_NIU

DECLARE @csql nvarchar(MAX);
SELECT @csql = ( SELECT ' UPDATE STATISTICS ' +
quotename(s.name) + '.' + quotename(o.name) +
' WITH FULLSCAN; ' + CHAR(13) AS [text()]
  FROM  sys.objects o
  JOIN  sys.schemas s ON o.schema_id = s.schema_id
  WHERE  o.type = 'U'
  FOR XML PATH(''), TYPE).value('.', 'nvarchar(MAX)');
PRINT @csql
 EXEC (@csql)
USE shiftconnector_CAO_PIC_PUD

DECLARE @csql nvarchar(MAX);
SELECT @csql = ( SELECT ' UPDATE STATISTICS ' +
quotename(s.name) + '.' + quotename(o.name) +
' WITH FULLSCAN; ' + CHAR(13) AS [text()]
  FROM  sys.objects o
  JOIN  sys.schemas s ON o.schema_id = s.schema_id
  WHERE  o.type = 'U'
  FOR XML PATH(''), TYPE).value('.', 'nvarchar(MAX)');
PRINT @csql
 EXEC (@csql)
USE shiftconnector_CAO_TDI1

DECLARE @csql nvarchar(MAX);
SELECT @csql = ( SELECT ' UPDATE STATISTICS ' +
quotename(s.name) + '.' + quotename(o.name) +
' WITH FULLSCAN; ' + CHAR(13) AS [text()]
  FROM  sys.objects o
  JOIN  sys.schemas s ON o.schema_id = s.schema_id
  WHERE  o.type = 'U'
  FOR XML PATH(''), TYPE).value('.', 'nvarchar(MAX)');
PRINT @csql
 EXEC (@csql)
USE shiftconnector_CAO_TDI2

DECLARE @csql nvarchar(MAX);
SELECT @csql = ( SELECT ' UPDATE STATISTICS ' +
quotename(s.name) + '.' + quotename(o.name) +
' WITH FULLSCAN; ' + CHAR(13) AS [text()]
  FROM  sys.objects o
  JOIN  sys.schemas s ON o.schema_id = s.schema_id
  WHERE  o.type = 'U'
  FOR XML PATH(''), TYPE).value('.', 'nvarchar(MAX)');
PRINT @csql
 EXEC (@csql)
USE shiftconnector_gsi

DECLARE @csql nvarchar(MAX);
SELECT @csql = ( SELECT ' UPDATE STATISTICS ' +
quotename(s.name) + '.' + quotename(o.name) +
' WITH FULLSCAN; ' + CHAR(13) AS [text()]
  FROM  sys.objects o
  JOIN  sys.schemas s ON o.schema_id = s.schema_id
  WHERE  o.type = 'U'
  FOR XML PATH(''), TYPE).value('.', 'nvarchar(MAX)');
PRINT @csql
 EXEC (@csql)
USE shiftconnector_GUA_CCDC

DECLARE @csql nvarchar(MAX);
SELECT @csql = ( SELECT ' UPDATE STATISTICS ' +
quotename(s.name) + '.' + quotename(o.name) +
' WITH FULLSCAN; ' + CHAR(13) AS [text()]
  FROM  sys.objects o
  JOIN  sys.schemas s ON o.schema_id = s.schema_id
  WHERE  o.type = 'U'
  FOR XML PATH(''), TYPE).value('.', 'nvarchar(MAX)');
PRINT @csql
 EXEC (@csql)
USE shiftconnector712_dashboards

DECLARE @csql nvarchar(MAX);
SELECT @csql = ( SELECT ' UPDATE STATISTICS ' +
quotename(s.name) + '.' + quotename(o.name) +
' WITH FULLSCAN; ' + CHAR(13) AS [text()]
  FROM  sys.objects o
  JOIN  sys.schemas s ON o.schema_id = s.schema_id
  WHERE  o.type = 'U'
  FOR XML PATH(''), TYPE).value('.', 'nvarchar(MAX)');
PRINT @csql
 EXEC (@csql)

USE shiftconnector712_test
DECLARE @csql nvarchar(MAX);
SELECT @csql = ( SELECT ' UPDATE STATISTICS ' +
quotename(s.name) + '.' + quotename(o.name) +
' WITH FULLSCAN; ' + CHAR(13) AS [text()]
  FROM  sys.objects o
  JOIN  sys.schemas s ON o.schema_id = s.schema_id
  WHERE  o.type = 'U'
  FOR XML PATH(''), TYPE).value('.', 'nvarchar(MAX)');
PRINT @csql
 EXEC (@csql)

USE shiftconnector75_legacy
DECLARE @csql nvarchar(MAX);
SELECT @csql = ( SELECT ' UPDATE STATISTICS ' +
quotename(s.name) + '.' + quotename(o.name) +
' WITH FULLSCAN; ' + CHAR(13) AS [text()]
  FROM  sys.objects o
  JOIN  sys.schemas s ON o.schema_id = s.schema_id
  WHERE  o.type = 'U'
  FOR XML PATH(''), TYPE).value('.', 'nvarchar(MAX)');
PRINT @csql
 EXEC (@csql)
