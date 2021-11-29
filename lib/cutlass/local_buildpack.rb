# frozen_string_literal: true

module Cutlass
  # Converts a buildpack in a local directory into an image that pack can use natively
  #
  #   MY_BUILDPACK = LocalBuildpack.new(directory: "/tmp/muh_buildpack").call
  #   puts MY_BUILDPACK.name #=> "docker:://cutlass_local_buildpack_abcd123"
  #
  #   Cutlass.config do |config|
  #     config.default_buildapacks = [MY_BUILDPACK]
  #   end
  #
  class LocalBuildpack
    def initialize(directory:)
      @directory = Pathname(directory)
      raise "must be directory: #{@directory}" unless @directory.directory?

      @build_sh = @directory.join("build.sh")
      @mutex_file = @directory.join(".cutlass_mutex")

      @target_directory = if @build_sh.exist?
        @directory.join("target")
      else
        @directory
      end

      @digest = digest_dir(@directory)
    end

    private def digest_dir(dir, digest = Digest::SHA256.new)
      dir.children.each do |child|
        next if child == @target_dir

        if child.file?
          digest << child.read
        else
          digest << child.to_s
          digest_dir(child, digest)
        end
      end
      digest
    end

    def file_lock
      file = File.open(@mutex_file, File::CREAT | File::RDWR)
      file.flock(File::LOCK_EX)
      yield file
    ensure
      file.close
    end

    def exist?
      @directory.exist?
    end

    def teardown
    end

    def name
      call

      @target_directory.expand_path
    end

    def call
      if @build_sh.exist?
        file_lock do |lock|
          if !@target_directory.exist? || lock.read.strip != @digest
            lock.puts @digest

            @target_directory.rmtree if @target_directory.exist?
            call_build_sh
          end
        end
      end

      self
    end

    private def call_build_sh
      command = "cd #{@directory} && bash #{@build_sh}"
      result = BashResult.run(command)

      puts command if Cutlass.debug?
      puts result.stdout if Cutlass.debug?
      puts result.stderr if Cutlass.debug?

      if result.success?
        raise "Expected #{@build_sh} to produce a directory #{@target_directory} but it did not" unless @target_directory.exist?
        return
      end

      raise <<~EOM
        Buildpack build step failed!

        stdout: #{result.stdout}
        stderr: #{result.stderr}
      EOM
    end
  end
end
