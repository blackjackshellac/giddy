#
# Giddy file entries
#

require 'fileutils'

require './lib/giddy/gentry'

describe Gentry do

	before(:all) do
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

		@file_sha="64074f40a6bd6941b68f48dd0c70ffd815e376a4cc0a799052bf390c2363ca33"
		@pack="10,8,4096,f,0xfd,0x00,27131915,1,0100664,1201,1201,1374430943,1374430943,1374430943"
		#@json=%Q/{"json_class":"Gentry","data":["file","10,8,4096,f,0xfd,0x00,27131915,1,0100664,1201,1201,1374430943,1374430943,1374430943","64074f40a6bd6941b68f48dd0c70ffd815e376a4cc0a799052bf390c2363ca33"]}/
		@json=%Q/{"name":"file","stat":"10,8,4096,f,0xfd,0x00,27131915,1,0100664,1201,1201,1374430943,1374430943,1374430943","sha2":"64074f40a6bd6941b68f48dd0c70ffd815e376a4cc0a799052bf390c2363ca33"}/
	end

	before(:each) do
		FileUtils.chdir(@test_dir)
	end

	after(:each) do
		FileUtils.chdir("..")
	end

	describe "initialize" do
		it "fails to create a new Gentry if file is null" do
			expect { Gentry.new(nil)}.to raise_error
		end

		it "fails to create a new Gentry if file is not found" do
			expect { Gentry.new("foo bar baz")}.to raise_error
		end

		it "creates a new Gentry for a regular file" do
			expect { Gentry.new(@file) }.to_not raise_error
		end

		it "creates a new Gentry for a directory" do
			expect { Gentry.new(".") }.to_not raise_error
		end

		it "creates a new Gentry for a file symlink" do
			expect { Gentry.new(@file_symlink) }.to_not raise_error
		end

		it "creates a new Gentry for a directory symlink" do
			expect { Gentry.new(@dir_symlink) }.to_not raise_error
		end
	end

	describe "test properties" do
		it "sets the name property" do
			ge=Gentry.new(@file)
			ge.name.should == @file
		end

		it "sets the sha for a file" do
			ge=Gentry.new(@file)
			ge.sha2.should == @file_sha
		end

		it "sets the gstat for a file" do
			ge=Gentry.new(@file)
			ge.stat.pack.should_not be nil
		end

		it "sets the content_dir and file" do
			ge=Gentry.new(@file, @pack)
			ge.content_dir.should == "64/07/4f/40"
			ge.content_file.should == "a6bd6941b68f48dd0c70ffd815e376a4cc0a799052bf390c2363ca33"
		end
	end

	describe "json tests" do
		before(:each) do
			@ge=Gentry.new(@file, @pack)
		end

		it "converts Gentry to json" do
			js=@ge.to_json
			#puts js
			js.should == @json
		end

		it "parses json to a Gentry",:parse=>true do
			ge=Gentry.from_json(@json)
			ge.class.should == Gentry
			#puts ge.inspect
			ge.eql?(@ge).should == true
		end
	end

	after(:all) do
		FileUtils.chdir(@test_dir) {
			%x/rm -fv empty file file_symlink dir_symlink/
		}
	end

end

