exec msdb.dbo.rds_restore_database
@restore_db_name='combitReportServer',
@s3_arn_to_restore_from='arn:aws:s3:::shiftconnector-db-backup-qa/combitReportServer.bak';
