-- Exporting the databases
GO
BACKUP DATABASE combitReportServer
TO DISK = '\\shiftconnector-ec2.713705977451.aws.glpoly.net\DatabaseMigration\qa\combitReportServer.bak'
WITH NOFORMAT,  STATS = 10, CHECKSUM

-- Uploading database exports to S3
-- aws s3 cp . s3://shiftconnector-db-backup-qa --recursive


