# frozen_string_literal: true

module Cutlass
  RSpec.describe Cutlass::FunctionQuery do
    it "calls an app built with a function invoker buildpack", slow: "extremely" do
      Cutlass::App.new(
        fixtures_path.join("jvm/sf-fx-template-java"),
        builder: "heroku/buildpacks:18",
        buildpacks: [
          "heroku/jvm@0.1.6",
          "heroku/maven@0.2.3",
          "urn:cnb:registry:heroku/jvm-function-invoker@0.2.7"
        ]
      ).transaction do |app|
        app.pack_build

        app.start_container(expose_ports: [8080]) do |container|
          query = Cutlass::FunctionQuery.new(port: container.get_host_port(8080)).call
          expect(query.as_json).to eq({"accounts" => []})
          expect(query.success?).to be_truthy
        end
      end
    end
  end
end
