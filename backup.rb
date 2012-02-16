
require 'cocaine'

module OrganizzeRedisBackup

  AWS_ACCESS_KEY = ENV["ORGANIZZE_AWS_ACCESS_KEY_ID"]
  AWS_SECRET_KEY = ENV["ORGANIZZE_AWS_SECRET_ACCESS_KEY"]
  RDB_PATH = ENV["RDB_PATH"]
  REDIS_BACKUP_FILE_PATH = ENV["REDIS_BACKUP_FILE_PATH"] || "/private/var/backups/redis"
  BUCKET_NAME = "organizze.backup.redis"

  class Backup

    def initialize
      Dir.chdir REDIS_BACKUP_FILE_PATH
      begin
        Dir.mkdir "files"
      rescue Errno::EEXIST
      end
    end

    def perform
      copy_files_to_temporary_directory
      gzip_files
      upload_to_s3!
      cleanup_working_directory
    end

    def working_directory
      Dir.pwd
    end

    def files_directory
      File.join(REDIS_BACKUP_FILE_PATH, "files")
    end

    def copy_files_to_temporary_directory
      Dir[File.join(RDB_PATH, "*")].each do |f|
        target = File.join(files_directory, File.basename(f))
        FileUtils.cp(f, target)
      end
    end

    def cleanup_working_directory
      Dir.chdir(REDIS_BACKUP_FILE_PATH)
      Dir["*"].each do |f|
        FileUtils.rm_rf(f)
      end
    end

    def gzip_files
      Dir.chdir REDIS_BACKUP_FILE_PATH
      @backup_file_name = "backup-redis-#{Time.now.to_i}.tar.gz"
      cmd = Cocaine::CommandLine.new "tar", "-zcvf :filename files",
        filename: @backup_file_name, swallow_stderr: true
      cmd.run
      @backup_file = File.open(@backup_file_name, 'r')
    end

    def upload_to_s3!
      storage = Fog::Storage.new(:provider => 'AWS',
                                 :aws_access_key_id => AWS_ACCESS_KEY,
                                 :aws_secret_access_key => AWS_SECRET_KEY)
      storage.put_object(BUCKET_NAME, @backup_file_name, @backup_file)
    end

  end

end

