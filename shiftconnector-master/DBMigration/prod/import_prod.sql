
-- Time needed approx 35 Minutes
exec msdb.dbo.rds_restore_database
@restore_db_name='BMS_Shift_Journal',
@s3_arn_to_restore_from='arn:aws:s3:::shiftconnector-db-backup-prod/BMS_Shift_Journal.bak';


-- Time needed approx xx Minutes
exec msdb.dbo.rds_restore_database
@restore_db_name='shiftconnector_CAO_CPU',
@s3_arn_to_restore_from='arn:aws:s3:::shiftconnector-db-backup-prod/shiftconnector_CAO_CPU.bak';
exec msdb.dbo.rds_restore_database
@restore_db_name='shiftconnector_CAO_HDI',
@s3_arn_to_restore_from='arn:aws:s3:::shiftconnector-db-backup-prod/shiftconnector_CAO_HDI.bak';
exec msdb.dbo.rds_restore_database
@restore_db_name='shiftconnector_CAO_MDI',
@s3_arn_to_restore_from='arn:aws:s3:::shiftconnector-db-backup-prod/shiftconnector_CAO_MDI.bak';
exec msdb.dbo.rds_restore_database
@restore_db_name='shiftconnector_CAO_MDI1',
@s3_arn_to_restore_from='arn:aws:s3:::shiftconnector-db-backup-prod/shiftconnector_CAO_MDI1.bak';
exec msdb.dbo.rds_restore_database
@restore_db_name='shiftconnector_CAO_NIU',
@s3_arn_to_restore_from='arn:aws:s3:::shiftconnector-db-backup-prod/shiftconnector_CAO_NIU.bak';
exec msdb.dbo.rds_restore_database
@restore_db_name='shiftconnector_CAO_PIC_PUD',
@s3_arn_to_restore_from='arn:aws:s3:::shiftconnector-db-backup-prod/shiftconnector_CAO_PIC_PUD.bak';
exec msdb.dbo.rds_restore_database
@restore_db_name='shiftconnector_CAO_TDI1',
@s3_arn_to_restore_from='arn:aws:s3:::shiftconnector-db-backup-prod/shiftconnector_CAO_TDI1.bak';
exec msdb.dbo.rds_restore_database
@restore_db_name='shiftconnector_CAO_TDI2',
@s3_arn_to_restore_from='arn:aws:s3:::shiftconnector-db-backup-prod/shiftconnector_CAO_TDI2.bak';
