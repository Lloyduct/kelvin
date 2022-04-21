exec msdb.dbo.rds_restore_database
@restore_db_name='combitReportServer',
@s3_arn_to_restore_from='arn:aws:s3:::shiftconnector-db-backup-qa/combitReportServer.bak';
exec msdb.dbo.rds_restore_database
@restore_db_name='shiftconnector_CAO_CPU',
@s3_arn_to_restore_from='arn:aws:s3:::shiftconnector-db-backup-qa/shiftconnector_CAO_CPU.bak';
exec msdb.dbo.rds_restore_database
@restore_db_name='shiftconnector_CAO_HDI',
@s3_arn_to_restore_from='arn:aws:s3:::shiftconnector-db-backup-qa/shiftconnector_CAO_HDI.bak';
exec msdb.dbo.rds_restore_database
@restore_db_name='shiftconnector_CAO_MDI',
@s3_arn_to_restore_from='arn:aws:s3:::shiftconnector-db-backup-qa/shiftconnector_CAO_MDI.bak';
exec msdb.dbo.rds_restore_database
@restore_db_name='shiftconnector_CAO_MDI1',
@s3_arn_to_restore_from='arn:aws:s3:::shiftconnector-db-backup-qa/shiftconnector_CAO_MDI1.bak';
exec msdb.dbo.rds_restore_database
@restore_db_name='shiftconnector_CAO_NIU',
@s3_arn_to_restore_from='arn:aws:s3:::shiftconnector-db-backup-qa/shiftconnector_CAO_NIU.bak';
exec msdb.dbo.rds_restore_database
@restore_db_name='shiftconnector_CAO_PIC_PUD',
@s3_arn_to_restore_from='arn:aws:s3:::shiftconnector-db-backup-qa/shiftconnector_CAO_PIC_PUD.bak';
exec msdb.dbo.rds_restore_database
@restore_db_name='shiftconnector_CAO_TDI1',
@s3_arn_to_restore_from='arn:aws:s3:::shiftconnector-db-backup-qa/shiftconnector_CAO_TDI1.bak';
exec msdb.dbo.rds_restore_database
@restore_db_name='shiftconnector_CAO_TDI2',
@s3_arn_to_restore_from='arn:aws:s3:::shiftconnector-db-backup-qa/shiftconnector_CAO_TDI2.bak';
exec msdb.dbo.rds_restore_database
@restore_db_name='shiftconnector_gsi',
@s3_arn_to_restore_from='arn:aws:s3:::shiftconnector-db-backup-qa/shiftconnector_gsi.bak';
exec msdb.dbo.rds_restore_database
@restore_db_name='shiftconnector_GUA_CCDC',
@s3_arn_to_restore_from='arn:aws:s3:::shiftconnector-db-backup-qa/shiftconnector_GUA_CCDC.bak';
exec msdb.dbo.rds_restore_database
@restore_db_name='shiftconnector712_dashboards',
@s3_arn_to_restore_from='arn:aws:s3:::shiftconnector-db-backup-qa/shiftconnector712_dashboards.bak';
exec msdb.dbo.rds_restore_database
@restore_db_name='shiftconnector712_test',
@s3_arn_to_restore_from='arn:aws:s3:::shiftconnector-db-backup-qa/shiftconnector712_test.bak';
exec msdb.dbo.rds_restore_database
@restore_db_name='shiftconnector75_legacy',
@s3_arn_to_restore_from='arn:aws:s3:::shiftconnector-db-backup-qa/shiftconnector75_legacy.bak';
exec msdb.dbo.rds_restore_database
@restore_db_name='shiftconnector75_test',
@s3_arn_to_restore_from='arn:aws:s3:::shiftconnector-db-backup-qa/shiftconnector75_test.bak';
exec msdb.dbo.rds_restore_database
@restore_db_name='shiftconnector79_test2',
@s3_arn_to_restore_from='arn:aws:s3:::shiftconnector-db-backup-qa/shiftconnector79_test2.bak';
