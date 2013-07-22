#
#
#

require 'fileutils'

require './lib/giddy/gstat'

describe Gstat do

	before(:all) do
		@home_dir=FileUtils.pwd
		@test_dir="test"
		FileUtils.chdir(@test_dir) {
			%x/echo > empty/
			%x/echo "not empty" > file/
			%x/ln -s file file_symlink/
			%x/ln -s . dir_symlink/

			@empty="empty"
			@file ="file"
			@file_symlink="file_symlink"
			@dir_symlink="dir_symlink"
		}
	end

	before(:each) do
		FileUtils.chdir(@test_dir)
	end

	describe "initialize" do
		it "fails to create a new Gstat if file is null" do
			expect { Gstat.new(nil)}.to raise_error
		end

		it "fails to create a new Gstat if file is not found" do
			expect { Gstat.new("foo bar baz")}.to raise_error
		end

		it "creates a new Gstat for a regular file" do
			expect { Gstat.new(@file) }.to_not raise_error
		end

		it "creates a new Gstat for a directory" do
			expect { Gstat.new(".") }.to_not raise_error
		end

		it "creates a new Gstat for a file symlink" do
			expect { Gstat.new(@file_symlink) }.to_not raise_error
		end

		it "creates a new Gstat for a directory symlink" do
			expect { Gstat.new(@dir_symlink) }.to_not raise_error
		end

		it "creates a new Gstat using pack data" do
			pack="10,8,4096,f,0xfd,0x00,27131915,1,0100664,1201,1201,1374430943,1374430943,1374430943"
			ge=Gstat.new(@file, pack)
			ge.pack.should == pack
		end
	end

	describe "test properties" do
		it "sets the name property" do
			ge=Gstat.new(@file)
			ge.name.should == @file
		end

		it "sets the sha for a file" do
			ge=Gstat.new(@file)
			ge.stat_sha2.should_not be nil
		end

		it "sets the gstat for a file" do
			ge=Gstat.new(@file)
			pack=ge.pack
			pack.should_not be nil
		end
	end

	after(:each) do
		FileUtils.chdir(@home_dir)
	end

	after(:all) do
		FileUtils.chdir(@test_dir) {
			%x/rm -fv empty file file_symlink dir_symlink/
		}
	end

end

