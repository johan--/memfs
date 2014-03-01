require 'spec_helper'

module MemFs
  describe Dir do
    subject { MemFs::Dir }

    before :each do
      subject.mkdir '/test'
    end

    describe '.chdir' do
      it "changes the current working directory" do
        subject.chdir '/test'
        expect(subject.getwd).to eq('/test')
      end

      it "returns zero" do
        expect(subject.chdir('/test')).to be_zero
      end

      it "raises an error when the folder does not exist" do
        expect { subject.chdir('/nowhere') }.to raise_error(Errno::ENOENT)
      end

      context "when a block is given" do
        it "changes current working directory for the block" do
          subject.chdir '/test' do
            expect(subject.pwd).to eq('/test')
          end
        end
    
        it "gets back to previous directory once the block is finished" do
          subject.chdir '/'
          expect {
            subject.chdir('/test') {}
          }.to_not change{subject.pwd}
        end
      end
    end

    describe ".delete" do
      it_behaves_like 'aliased method', :delete, :rmdir
    end

    describe '.entries' do
      it "returns an array containing all of the filenames in the given directory" do
        %w[/test/dir1 /test/dir2].each { |dir| subject.mkdir dir }
        fs.touch '/test/file1', '/test/file2'
        expect(subject.entries('/test')).to eq(%w[. .. dir1 dir2 file1 file2])
      end
    end

    describe ".exist?" do
      it_behaves_like 'aliased method', :exist?, :exists?
    end

    describe ".exists?" do
      it "returns true if the given +path+ exists and is a directory" do
        subject.mkdir('/test-dir')
        expect(subject.exists?('/test-dir')).to be_true
      end

      it "returns false if the given +path+ does not exist" do
        expect(subject.exists?('/test-dir')).to be_false
      end

      it "returns false if the given +path+ is not a directory" do
        fs.touch('/test-file')
        expect(subject.exists?('/test-file')).to be_false
      end
    end

    describe ".foreach" do
      before :each do
        fs.mkdir('/test-dir')
        fs.touch('/test-dir/test-file', '/test-dir/test-file2')
      end

      context "when a block is given" do
        it "calls the block once for each entry in the named directory" do
          expect{ |blk|
            subject.foreach('/test-dir', &blk)
          }.to yield_control.exactly(4).times
        end

        it "passes each entry as a parameter to the block" do
          expect{ |blk|
            subject.foreach('/test-dir', &blk)
          }.to yield_successive_args('.', '..', 'test-file', 'test-file2')
        end

        context "and the directory doesn't exist" do
          it "raises an exception" do
            expect{ subject.foreach('/no-dir') {} }.to raise_error
          end
        end

        context "and the given path is not a directory" do
          it "raises an exception" do
            expect{
              subject.foreach('/test-dir/test-file') {}
            }.to raise_error
          end
        end
      end

      context "when no block is given" do
        it "returns an enumerator" do
          list = subject.foreach('/test-dir')
          expect(list).to be_an(Enumerator)
        end

        context "and the directory doesn't exist" do
          it "returns an enumerator" do
            list = subject.foreach('/no-dir')
            expect(list).to be_an(Enumerator)
          end
        end

        context "and the given path is not a directory" do
          it "returns an enumerator" do
            list = subject.foreach('/test-dir/test-file')
            expect(list).to be_an(Enumerator)
          end
        end
      end
    end

    describe '.getwd' do
      it "returns the path to the current working directory" do
        expect(subject.getwd).to eq(FileSystem.instance.getwd)
      end
    end

    describe '.mkdir' do
      it "creates a directory" do
        subject.mkdir '/new-folder'
        expect(File.directory?('/new-folder')).to be_true
      end

      context "when the directory already exist" do
        it "raises an exception" do
          expect { subject.mkdir('/') }.to raise_error(Errno::EEXIST)
        end
      end
    end

    describe ".pwd" do
      it_behaves_like 'aliased method', :pwd, :getwd
    end

    describe ".rmdir" do
      it "deletes the named directory" do
        subject.mkdir('/test-dir')
        subject.rmdir('/test-dir')
        expect(subject.exists?('/test-dir')).to be_false
      end

      context "when the directory is not empty" do
        it "raises an exception" do
          subject.mkdir('/test-dir')
          subject.mkdir('/test-dir/test-sub-dir')
          expect { subject.rmdir('/test-dir') }.to raise_error(Errno::ENOTEMPTY)
        end
      end
    end

    describe ".unlink" do
      it_behaves_like 'aliased method', :unlink, :rmdir
    end
  end
end
