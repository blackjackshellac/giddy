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
		@pack="10,8,4096,f,0xfd,0x00,27131915,1,0100664,1201,1201,1374430943,1374430943,1374430943"
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
			gs=Gstat.new(@file, @pack)
			gs.pack.should == @pack
		end
	end

	describe "test properties" do
		it "sets the name property" do
			gs=Gstat.new(@file)
			gs.name.should == @file
		end

		it "sets the sha for a file" do
			gs=Gstat.new(@file, @pack)
			gs.stat_sha2.should == "64e6ef8f20cfc54e508f7d14d27e5e2c68ca90286dbf600e6320857fd452d85e"
		end

		it "sets the gstat for a file" do
			gs=Gstat.new(@file, @pack)
			gs.pack.should == @pack
		end
	end

	describe "test comparison" do
		it "is not equal if parameter is null" do
			gs=Gstat.new(@file)
			gs.eql?(nil).should be false
		end

		it "is equal for same data" do
			gs=Gstat.new(@file, @pack)
			gt=Gstat.new(@file, @pack)
			gs.eql?(gt).should be true
		end

		it "is not equal for same file, different stat" do
			gs=Gstat.new(@file, @pack)
			# this will be new stat data
			gt=Gstat.new(@file)
			gs.eql?(gt).should be false
		end

		it "is not equal for symlink and the file to which it is linked" do
			gs=Gstat.new(@file)
			gl=Gstat.new(@file_symlink)
			gs.eql?(gl).should be false
		end

		it "is equal for same directory" do
			gs=Gstat.new(@home_dir)
			gt=Gstat.new(@home_dir)
			gs.eql?(gt).should be true 
		end

		it "is equal for different directory" do
			gs=Gstat.new(@home_dir)
			gt=Gstat.new(".")
			gs.eql?(gt).should be false
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

