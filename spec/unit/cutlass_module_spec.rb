# frozen_string_literal: true

module Cutlass
  RSpec.describe Cutlass do
    it "is configurable" do
      Dir.mktmpdir do |dir|
        Cutlass.in_fork do
          Cutlass.config do |config|
            config.default_builder = "foo/bar"
            config.default_repo_dirs = ["foo"]
            config.default_buildpack_paths = [dir]
          end

          expect(Cutlass.default_builder).to eq("foo/bar")
          expect(Cutlass.default_repo_dirs.map(&:to_s)).to eq(["foo"])
          expect(Cutlass.default_buildpack_paths.map(&:to_s)).to eq([dir])
        end
      end
    end

    it "accepts a local buildpack" do
      Dir.mktmpdir do |dir|
        Cutlass.in_fork do
          buildpack = LocalBuildpack.new(directory: dir)
          Cutlass.config do |config|
            config.default_buildpack_paths = [buildpack, "heroku/procfile@0.6.2"]
          end
        ensure
          buildpack&.teardown
        end
      end
    end

    it "resolves directories" do
      Cutlass.in_fork do
        Dir.mktmpdir do |dir|
          dir = Pathname(dir)

          names = ["dog", "cat", "bat"]
          dirs = names.map { |name| dir.join(name) }
          dirs.each(&:mkdir)

          Cutlass.config do |config|
            config.default_repo_dirs = dir
          end

          names.each do |name|
            path = Cutlass.resolve_path(name)
            expect(path).to exist
          end
        end
      end
    end

    it "raises on directories that don't exist" do
      expect {
        Cutlass.resolve_path("should raise error")
      }.to raise_error(/No such directory name:/)
    end

    it "returns if given a directory that already exists" do
      Dir.mktmpdir do |dir|
        path = Cutlass.resolve_path(dir)
        expect(path).to exist
      end
    end
  end
end
