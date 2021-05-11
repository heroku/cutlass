# frozen_string_literal: true

module Cutlass
  RSpec.describe Cutlass::FunctionQuery do
    describe "webmock tests" do
      before(:each) do
        WebMock.enable!
      end

      after(:each) do
        WebMock.disable!
      end

      it "port" do
        port = rand(1000...9999)
        stub_request(:any, "localhost:#{port}")

        Cutlass::FunctionQuery.new(
          port: port
        ).call

        expect(WebMock).to have_requested(:post, "localhost:#{port}")
          .with(body: "{}")
      end

      it "body" do
        body = {lol: "hi #{SecureRandom.hex}"}
        port = 8080
        stub_request(:any, "localhost:#{port}")

        Cutlass::FunctionQuery.new(
          port: port,
          body: body
        ).call

        expect(WebMock).to have_requested(:post, "localhost:#{port}")
          .with(body: body.to_json)
      end

      it "spec version" do
        port = 8080
        stub_request(:any, "localhost:#{port}")

        Cutlass::FunctionQuery.new(
          port: port,
          spec_version: "lol"
        ).call

        expect(WebMock).to have_requested(:post, "localhost:#{port}")
          .with(headers: {
            "Ce-Specversion" => "lol"
          })
      end
    end

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
          body = "hello"
          query = Cutlass::FunctionQuery.new(
            port: container.get_host_port(8080),
            body: body
          ).call
          expect(query.as_json).to eq(body.reverse)
          expect(query.success?).to be_truthy
        end
      end
    end
  end
end
