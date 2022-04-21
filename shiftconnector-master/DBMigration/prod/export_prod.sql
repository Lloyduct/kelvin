-- Exporting the databases, Approximately 35 minutes
GO
BACKUP DATABASE BMS_Shift_Journal
TO DISK = '\\shiftconnector-ec2.554250442952.aws.glpoly.net\DBExport\prod\BMS_Shift_Journal.bak'
WITH NOFORMAT,  STATS = 10, CHECKSUM
GO




-- Exporting the databases, Approximately 17 minutes
GO
BACKUP DATABASE shiftconnector_CAO_CPU
TO DISK = '\\shiftconnector-ec2.554250442952.aws.glpoly.net\DBExport\prod\shiftconnector_CAO_CPU.bak'
WITH NOFORMAT,  STATS = 10, CHECKSUM
GO
GO
BACKUP DATABASE shiftconnector_CAO_HDI
TO DISK = '\\shiftconnector-ec2.554250442952.aws.glpoly.net\DBExport\prod\shiftconnector_CAO_HDI.bak'
WITH NOFORMAT,  STATS = 10, CHECKSUM
GO
GO
BACKUP DATABASE shiftconnector_CAO_MDI
TO DISK = '\\shiftconnector-ec2.554250442952.aws.glpoly.net\DBExport\prod\shiftconnector_CAO_MDI.bak'
WITH NOFORMAT,  STATS = 10, CHECKSUM
GO
GO
BACKUP DATABASE shiftconnector_CAO_MDI1
TO DISK = '\\shiftconnector-ec2.554250442952.aws.glpoly.net\DBExport\prod\shiftconnector_CAO_MDI1.bak'
WITH NOFORMAT,  STATS = 10, CHECKSUM
GO
GO
BACKUP DATABASE shiftconnector_CAO_NIU
TO DISK = '\\shiftconnector-ec2.554250442952.aws.glpoly.net\DBExport\prod\shiftconnector_CAO_NIU.bak'
WITH NOFORMAT,  STATS = 10, CHECKSUM
GO
GO
BACKUP DATABASE shiftconnector_CAO_PIC_PUD
TO DISK = '\\shiftconnector-ec2.554250442952.aws.glpoly.net\DBExport\prod\shiftconnector_CAO_PIC_PUD.bak'
WITH NOFORMAT,  STATS = 10, CHECKSUM
GO
GO
BACKUP DATABASE shiftconnector_CAO_TDI1
TO DISK = '\\shiftconnector-ec2.554250442952.aws.glpoly.net\DBExport\prod\shiftconnector_CAO_TDI1.bak'
WITH NOFORMAT,  STATS = 10, CHECKSUM
GO
GO
BACKUP DATABASE shiftconnector_CAO_TDI2
TO DISK = '\\shiftconnector-ec2.554250442952.aws.glpoly.net\DBExport\prod\shiftconnector_CAO_TDI2.bak'
WITH NOFORMAT,  STATS = 10, CHECKSUM
GO

-- Uploading database exports to S3 - approximately 23 minutes
-- aws s3 cp .\BMS_Shift_Journal.bak s3://shiftconnector-db-backup-prod

-- Uploading database exports to S3 - approximately 10 minutes
-- aws s3 cp . s3://shiftconnector-db-backup-prod --recursive


