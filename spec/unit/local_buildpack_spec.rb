# frozen_string_literal: true

module Cutlass
  RSpec.describe Cutlass::LocalBuildpack do
    it "locks" do
      Dir.mktmpdir do |dir|
        buildpack = LocalBuildpack.new(directory: dir)
        file = Tempfile.new
        path = Pathname(file.path)

        threads = []
        10.times do
          threads << Thread.new do
            10.times.each do
              buildpack.file_lock do
                path.write(Thread.current.object_id.to_s)
                expect(path.read.strip).to eq(Thread.current.object_id.to_s)
              end
            end
          end
        end

        threads.map(&:join)
      end
    end

    it "builds images and tears them down while calling build.sh if it exists", slow: true do
      Dir.mktmpdir do |dir|
        name = SecureRandom.hex(10)
        dir = Pathname(dir)
        dir.join("build.sh").tap do |script|
          script.write(<<~EOM)
            mkdir target
            touch #{name}

            cat << EOF >> target/package.toml
              [buildpack]
              uri = "."
            EOF

            cat << EOF >> target/buildpack.toml
              [buildpack]
              id = "cutlass/supreme_#{name}"
              version = "0.0.1"

              [[stacks]]
              id = "io.buildpacks.stacks.bionic"
            EOF
          EOM

          FileUtils.chmod("+x", script)
        end

        diff = DockerDiff.new
        local_buildpack = LocalBuildpack.new(directory: dir)
        local_buildpack.call

        expect(dir.entries.map(&:to_s)).to include(name)

        expect(diff.call.changed?).to be_falsey
        local_buildpack&.teardown

        expect(diff.call.changed?).to be_falsey
      end
    end
  end
end
