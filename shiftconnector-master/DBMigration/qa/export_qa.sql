-- Exporting the databases
GO
BACKUP DATABASE combitReportServer
TO DISK = '\\shiftconnector-ec2.713705977451.aws.glpoly.net\DatabaseMigration\qa\combitReportServer.bak'
WITH NOFORMAT,  STATS = 10, CHECKSUM
GO
GO
BACKUP DATABASE shiftconnector_CAO_CPU
TO DISK = '\\shiftconnector-ec2.713705977451.aws.glpoly.net\DatabaseMigration\qa\shiftconnector_CAO_CPU.bak'
WITH NOFORMAT,  STATS = 10, CHECKSUM
GO
GO
BACKUP DATABASE shiftconnector_CAO_HDI
TO DISK = '\\shiftconnector-ec2.713705977451.aws.glpoly.net\DatabaseMigration\qa\shiftconnector_CAO_HDI.bak'
WITH NOFORMAT,  STATS = 10, CHECKSUM
GO
GO
BACKUP DATABASE shiftconnector_CAO_MDI
TO DISK = '\\shiftconnector-ec2.713705977451.aws.glpoly.net\DatabaseMigration\qa\shiftconnector_CAO_MDI.bak'
WITH NOFORMAT,  STATS = 10, CHECKSUM
GO
GO
BACKUP DATABASE shiftconnector_CAO_MDI1
TO DISK = '\\shiftconnector-ec2.713705977451.aws.glpoly.net\DatabaseMigration\qa\shiftconnector_CAO_MDI1.bak'
WITH NOFORMAT,  STATS = 10, CHECKSUM
GO
GO
BACKUP DATABASE shiftconnector_CAO_NIU
TO DISK = '\\shiftconnector-ec2.713705977451.aws.glpoly.net\DatabaseMigration\qa\shiftconnector_CAO_NIU.bak'
WITH NOFORMAT,  STATS = 10, CHECKSUM
GO
GO
BACKUP DATABASE shiftconnector_CAO_PIC_PUD
TO DISK = '\\shiftconnector-ec2.713705977451.aws.glpoly.net\DatabaseMigration\qa\shiftconnector_CAO_PIC_PUD.bak'
WITH NOFORMAT,  STATS = 10, CHECKSUM
GO
GO
BACKUP DATABASE shiftconnector_CAO_TDI1
TO DISK = '\\shiftconnector-ec2.713705977451.aws.glpoly.net\DatabaseMigration\qa\shiftconnector_CAO_TDI1.bak'
WITH NOFORMAT,  STATS = 10, CHECKSUM
GO
GO
BACKUP DATABASE shiftconnector_CAO_TDI2
TO DISK = '\\shiftconnector-ec2.713705977451.aws.glpoly.net\DatabaseMigration\qa\shiftconnector_CAO_TDI2.bak'
WITH NOFORMAT,  STATS = 10, CHECKSUM
GO
GO
BACKUP DATABASE shiftconnector_gsi
TO DISK = '\\shiftconnector-ec2.713705977451.aws.glpoly.net\DatabaseMigration\qa\shiftconnector_gsi.bak'
WITH NOFORMAT,  STATS = 10, CHECKSUM
GO
GO
BACKUP DATABASE shiftconnector_GUA_CCDC
TO DISK = '\\shiftconnector-ec2.713705977451.aws.glpoly.net\DatabaseMigration\qa\shiftconnector_GUA_CCDC.bak'
WITH NOFORMAT,  STATS = 10, CHECKSUM
GO
GO
BACKUP DATABASE shiftconnector712_dashboards
TO DISK = '\\shiftconnector-ec2.713705977451.aws.glpoly.net\DatabaseMigration\qa\shiftconnector712_dashboards.bak'
WITH NOFORMAT,  STATS = 10, CHECKSUM
GO
GO
BACKUP DATABASE shiftconnector712_test
TO DISK = '\\shiftconnector-ec2.713705977451.aws.glpoly.net\DatabaseMigration\qa\shiftconnector712_test.bak'
WITH NOFORMAT,  STATS = 10, CHECKSUM
GO
GO
BACKUP DATABASE shiftconnector75_legacy
TO DISK = '\\shiftconnector-ec2.713705977451.aws.glpoly.net\DatabaseMigration\qa\shiftconnector75_legacy.bak'
WITH NOFORMAT,  STATS = 10, CHECKSUM
GO
GO
BACKUP DATABASE shiftconnector75_test
TO DISK = '\\shiftconnector-ec2.713705977451.aws.glpoly.net\DatabaseMigration\qa\shiftconnector75_test.bak'
WITH NOFORMAT,  STATS = 10, CHECKSUM
GO
GO
BACKUP DATABASE shiftconnector79_test2
TO DISK = '\\shiftconnector-ec2.713705977451.aws.glpoly.net\DatabaseMigration\qa\shiftconnector79_test2.bak'
WITH NOFORMAT,  STATS = 10, CHECKSUM
GO


-- Uploading database exports to S3
-- aws s3 cp . s3://shiftconnector-db-backup-qa --recursive


