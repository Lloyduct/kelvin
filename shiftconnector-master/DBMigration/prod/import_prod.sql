
-- Time needed approx 35 Minutes
exec msdb.dbo.rds_restore_database
@restore_db_name='BMS_Shift_Journal',
@s3_arn_to_restore_from='arn:aws:s3:::shifddftconnector-db-backup-prod/BMS_Shift_Journal.bak';
