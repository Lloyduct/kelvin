-- Exporting the databases, Approximately 35 minutes
GO
BACKUP DATABASE BMS_Shift_Journal
TO DISK = '\\shiftconnector-ec2.234554250442952.aws.glpoly.net\DBExport\prod\BMS_Shift_Journal.bak'
WITH NOFORMAT,  STATS = 10, CHECKSUM
GO


-- Uploading database exports to S3 - approximately 23 minutes
-- aws s3 cp .\BMS_Shift_Journal.bak s3://shiftconnector-db-backup-prod

-- Uploading database exports to S3 - approximately 10 minutes
-- aws s3 cp . s3://shiftconnddfector-db-backup-prod --recursive


