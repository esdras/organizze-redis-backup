require 'rspec'
require File.join(File.dirname(__FILE__), '..', 'backup')

describe OrganizzeRedisBackup::Backup do

  subject { OrganizzeRedisBackup::Backup.new }

  its(:working_directory) { should == OrganizzeRedisBackup::REDIS_BACKUP_FILE_PATH }

  it "should copy dump file to the working directory" do
    Dir.chdir OrganizzeRedisBackup::RDB_PATH
    dump_files = Dir["*"]
    Dir.chdir subject.files_directory
    subject.copy_files_to_temporary_directory
    copied_files = Dir["*"]
    copied_files.should_not be_empty
    copied_files.all? { |f| dump_files.include?(f) }.should be_true
  end

  it "should gzip files" do
    subject.copy_files_to_temporary_directory
    subject.gzip_files
    Dir["*"].any? do |f|
      File.extname(f) == ".gz"
    end.should be_true
  end

  after(:each) do
    Dir.chdir(OrganizzeRedisBackup::REDIS_BACKUP_FILE_PATH)
    Dir["*"].each do |f|
      FileUtils.rm_rf(f)
    end
  end

end
