load File.join(File.dirname(__FILE__), '../../init.rb')

describe Library do

  it "generate" do
    Library.with_temp_file do |path|
      template = InstallTemplate.new(:lib_dir => path, :bin_dir => File.join(path, "bin"))
      contents = template.generate
      contents.index(/CONVENTIONS.md/).should > 0
      contents.index(/README.md/).should > 0
      contents.index(/LICENSE/).should > 0
      contents.index(/VERSION/).should > 0
    end
  end

  it "write_to_file" do
    Library.with_temp_file do |dir|
      Library.with_temp_file do |install_file|
        template = InstallTemplate.new(:lib_dir => dir, :bin_dir => File.join(dir, "bin"))
        template.write_to_file(install_file)
        File.exists?(install_file).should be_true
      end
    end
  end

  it "parses template successfully" do
    contents = InstallTemplate.new(:lib_dir => "/tmp", :bin_dir => '/tmp/bin').generate
    if value = contents.index('%%')
      fail("Template contains %% at position #{value}")
    end
  end

  it "written file installs correctly" do
    Dir.chdir(Library.base_dir) do
      install_file = "unit_test_install.#{Process.pid}.rb"

      # List of files in root directory that should be copied over
      root_files = Dir.glob("#{Library.base_dir}/*").select { |f| File.file?(f) && !f.match(/\.rb$/) }.map { |f| File.basename(f) }

      Library.with_temp_file do |dir|
        template = InstallTemplate.new(:lib_dir => dir, :bin_dir => File.join(dir, "bin"))
        begin
          template.write_to_file(install_file)
          File.exists?(install_file).should be_true
          Library.system_or_error(install_file)
          File.directory?(dir).should be_true
          version_dir = "schema-evolution-manager-%s" % [Version.read.to_version_string]
          File.symlink?(File.join(dir, "schema-evolution-manager")).should be_true
          File.readlink(File.join(dir, "schema-evolution-manager")).should == version_dir
          File.directory?(File.join(dir, version_dir, "bin")).should be_true
          File.directory?(File.join(dir, version_dir, "lib")).should be_true
          root_files.each do |file|
            if file.match(/\~/) || file.match(/^\#/)
              next
            end
            if !File.file?(File.join(dir, version_dir, file))
              fail("File[%s] missing from install dir[%s]" % [file, dir])
            end
          end
        ensure
          File.delete(install_file)
        end
      end
    end
  end

end
