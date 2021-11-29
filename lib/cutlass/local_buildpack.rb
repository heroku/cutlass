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
  # Note: Make sure that any built images are torn down in in your test suite
  #
  #    config.after(:suite) do
  #      MY_BUILDPACK.teardown
  #
  #      Cutlass::CleanTestEnv.check
  #    end
  #
  class LocalBuildpack
    private

    attr_reader :image_name

    public

    def initialize(directory:)
      @built = false
      @directory = Pathname(directory)
      @image_name = "cutlass_local_buildpack_#{SecureRandom.hex(10)}"

      @mutex_file = Tempfile.new
    end

    def file_lock
      file = File.open(@mutex_file.path, File::CREAT)
      file.flock(File::LOCK_EX)
      yield
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
      @directory.expand_path
    end

    def call
      file_lock do
        return if built?
        raise "must be directory: #{@directory}" unless @directory.directory?
        @built = true

        call_build_sh
      end

      self
    end

    private def call_build_sh
      build_sh = @directory.join("build.sh")
      return unless build_sh.exist?

      command = "cd #{@directory} && bash #{build_sh}"
      result = BashResult.run(command)

      puts command if Cutlass.debug?
      puts result.stdout if Cutlass.debug?
      puts result.stderr if Cutlass.debug?

      if result.success?
        @directory = @directory.join("target")
        raise "Expected #{build_sh} to produce a directory #{@directory} but it did not" unless @directory.exist?
        return
      end

      raise <<~EOM
        Buildpack build step failed!

        stdout: #{result.stdout}
        stderr: #{result.stderr}
      EOM
    end

    def built?
      @built
    end
  end
end
