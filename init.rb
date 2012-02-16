require File.join(File.dirname(__FILE__), 'backup')
bkp = OrganizzeRedisBackup::Backup.new
bkp.perform
