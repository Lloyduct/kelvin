-- Setting COMPATIBILITY to 2019, 0 mins
ALTER DATABASE BMS_Shift_Journal SET COMPATIBILITY_LEVEL = 150 
ALTER DATABASE shiftconnector_CAO_CPU SET COMPATIBILITY_LEVEL = 150 
ALTER DATABASE shiftconnector_CAO_HDI SET COMPATIBILITY_LEVEL = 150 
ALTER DATABASE shiftconnector_CAO_MDI SET COMPATIBILITY_LEVEL = 150 
ALTER DATABASE shiftconnector_CAO_MDI1 SET COMPATIBILITY_LEVEL = 150 
ALTER DATABASE shiftconnector_CAO_NIU SET COMPATIBILITY_LEVEL = 150 
ALTER DATABASE shiftconnector_CAO_PIC_PUD SET COMPATIBILITY_LEVEL = 150 
ALTER DATABASE shiftconnector_CAO_TDI1 SET COMPATIBILITY_LEVEL = 150 
ALTER DATABASE shiftconnector_CAO_TDI2 SET COMPATIBILITY_LEVEL = 150 


-- Time needed:    9 mins
DBCC UPDATEUSAGE('BMS_Shift_Journal') WITH COUNT_ROWS




DBCC UPDATEUSAGE('shiftconnector_CAO_CPU') WITH COUNT_ROWS
DBCC UPDATEUSAGE('shiftconnector_CAO_HDI') WITH COUNT_ROWS
DBCC UPDATEUSAGE('shiftconnector_CAO_MDI') WITH COUNT_ROWS
DBCC UPDATEUSAGE('shiftconnector_CAO_MDI1') WITH COUNT_ROWS
DBCC UPDATEUSAGE('shiftconnector_CAO_NIU') WITH COUNT_ROWS
DBCC UPDATEUSAGE('shiftconnector_CAO_PIC_PUD') WITH COUNT_ROWS
DBCC UPDATEUSAGE('shiftconnector_CAO_TDI1') WITH COUNT_ROWS
DBCC UPDATEUSAGE('shiftconnector_CAO_TDI2') WITH COUNT_ROWS

USE [master]
--- 
-- Rebuild Indexes 
-- Time needed:    5  mins

DECLARE @Database NVARCHAR(255)   
DECLARE @Table NVARCHAR(255)  
DECLARE @cmd NVARCHAR(1000)  

DECLARE DatabaseCursor CURSOR READ_ONLY FOR  
SELECT name FROM master.sys.databases   
WHERE name NOT IN ('master','msdb','tempdb','model','distribution','rdsadmin','BMS_Shift_Journal')  -- databases to exclude
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


USE [master]
--- 
-- Rebuild Indexes
-- Time needed:    12  mins
DECLARE @Database NVARCHAR(255)   
DECLARE @Table NVARCHAR(255)  
DECLARE @cmd NVARCHAR(1000)  
DECLARE @t1 DATETIME;
DECLARE @t2 DATETIME;
DECLARE @p1 NVARCHAR(255) 

DECLARE DatabaseCursor CURSOR READ_ONLY FOR  
SELECT name FROM master.sys.databases   
WHERE name IN ('BMS_Shift_Journal') -- use this to select specific databases and comment out line above
AND state = 0 -- database is online
AND is_in_standby = 0 -- database is not read only for log shipping
ORDER BY 1  
OPEN DatabaseCursor  
FETCH NEXT FROM DatabaseCursor INTO @Database  
WHILE @@FETCH_STATUS = 0  
BEGIN  
   SET @cmd = 'DECLARE TableCursor CURSOR READ_ONLY FOR SELECT ''['' + table_catalog + ''].['' + table_schema + ''].['' +  
   table_name + '']'' as tableName FROM [BMS_Shift_Journal].INFORMATION_SCHEMA.TABLES WHERE table_type = ''BASE TABLE'' AND table_name not in (''EntryItemHistory_To_User'',''EntryItemHistory_To_Shift'',''EntryItemHistory'',''EntryItem'',''EntryItemHistory_To_BusinessFieldListValue'',''EntryItem_To_Shift'',''FunctionalLocation'',''EntryItem_To_BusinessFieldListValue'')'   
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
        SET @t1 = GETDATE();
         SET @cmd = 'ALTER INDEX ALL ON ' + @Table + ' REBUILD' 
         
         EXEC (@cmd) 
        SET @t2 = GETDATE();
        SET @p1 = (SELECT DATEDIFF(SECOND,@t1,@t2) AS Second)
        PRINT(@cmd + ' - Executed in s: ' + @p1)  -- uncomment if you want to see commands
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


--- 
-- Rebuild Indexes
--  ~ 15 min
ALTER INDEX ALL ON [BMS_Shift_Journal].[dbo].[EntryItemHistory_To_User] REBUILD;  -- 9 minutes: 
ALTER INDEX ALL ON [BMS_Shift_Journal].[dbo].[EntryItemHistory_To_Shift] REBUILD; -- 13 minutes: 
ALTER INDEX ALL ON [BMS_Shift_Journal].[dbo].[EntryItemHistory] REBUILD; -- 9 minutes: 
ALTER INDEX ALL ON [BMS_Shift_Journal].[dbo].[EntryItem] REBUILD; -- 12 minutes: 
ALTER INDEX ALL ON [BMS_Shift_Journal].[dbo].[EntryItemHistory_To_BusinessFieldListValue] REBUILD; -- 4 minutes: 
ALTER INDEX ALL ON [BMS_Shift_Journal].[dbo].[EntryItem_To_Shift] REBUILD; -- 4 minutes: 
ALTER INDEX ALL ON [BMS_Shift_Journal].[dbo].[FunctionalLocation] REBUILD; -- 3,5 minutes: 
ALTER INDEX ALL ON [BMS_Shift_Journal].[dbo].[EntryItem_To_BusinessFieldListValue] REBUILD; -- 3,5 minutes: 



-- Update Usage Stats
-- Time Needed: 15 mins
USE [BMS_Shift_Journal]
DECLARE @UpdateStatement NVARCHAR(255)   
DECLARE @t1 DATETIME;
DECLARE @t2 DATETIME;
DECLARE @p1 NVARCHAR(255) 

DECLARE UpdateCursor CURSOR READ_ONLY FOR  
SELECT 'UPDATE STATISTICS ' +
quotename(s.name) + '.' + quotename(o.name) +
' WITH FULLSCAN; '
  FROM  sys.objects o
  JOIN  sys.schemas s ON o.schema_id = s.schema_id
  WHERE  o.type = 'U' AND o.name NOT IN ('CustomFields','CustomFieldsHistory','File','EntryItem','EntryItemHistory','EntryItemHistory_To_User','EntryItemHistory_To_Shift')
OPEN UpdateCursor  
FETCH NEXT FROM UpdateCursor INTO @UpdateStatement  
WHILE @@FETCH_STATUS = 0  
BEGIN  
  SET @t1 = GETDATE();
  PRINT @UpdateStatement
  EXEC(@UpdateStatement)
	SET @t2 = GETDATE();
	SET @p1 = (SELECT DATEDIFF(SECOND,@t1,@t2) AS Second)
	PRINT('Executiontime in seconds: ' + @p1  + CHAR(13))
  FETCH NEXT FROM UpdateCursor INTO @UpdateStatement  
END  
CLOSE UpdateCursor   
DEALLOCATE UpdateCursor


-- Update Usage Stats
-- Time Needed: ~ 12 mins
UPDATE STATISTICS [dbo].[CustomFields] WITH SAMPLE 10 PERCENT; -- 15 minutes
UPDATE STATISTICS [dbo].[CustomFieldsHistory] WITH SAMPLE 10 PERCENT; -- 15 minutes 
UPDATE STATISTICS [dbo].[File] WITH SAMPLE 20 PERCENT;  -- 15 minutes
UPDATE STATISTICS [dbo].[EntryItem] WITH FULLSCAN;  -- 11 minutes
UPDATE STATISTICS [dbo].[EntryItemHistory] WITH FULLSCAN; -- 11 minutes
UPDATE STATISTICS [dbo].[EntryItemHistory_To_User] WITH FULLSCAN;-- 10 minutes
UPDATE STATISTICS [dbo].[EntryItemHistory_To_Shift] WITH FULLSCAN; -- 16 minutes




-- Update Usage Stats
-- Time Needed: 6 mins

USE shiftconnector_CAO_CPU
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
SELECT @csql = ( SELECT ' UPDATE STATISTICS ' +
quotename(s.name) + '.' + quotename(o.name) +
' WITH FULLSCAN; ' + CHAR(13) AS [text()]
  FROM  sys.objects o
  JOIN  sys.schemas s ON o.schema_id = s.schema_id
  WHERE  o.type = 'U'
  FOR XML PATH(''), TYPE).value('.', 'nvarchar(MAX)');
PRINT @csql
 EXEC (@csql)
