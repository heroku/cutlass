# frozen_string_literal: true

require "json"
require "base64"
require "cgi"

module Cutlass
  # The purpose of this class is to trigger "Salesforce Functions"
  # against a function compatible app built with a compatible CNB
  #
  # This class is WIP, API is subject to change
  #
  #     app.start_container(expose_ports: [8080]) do |container|
  #       Cutlass::FunctionQuery.new(port: container.get_host_port(8080)).call.as_json
  #       # => { accounts: []}
  #     end
  #
  class FunctionQuery
    attr_reader :io

    def initialize(port:, spec_version: nil, body: {}, io: Kernel)
      @send_body = body
      @port = port
      @response = nil
      @spec_version = spec_version || "1.0"
      @io = io
    end

    def call
      @response = Excon.post(
        "http://localhost:#{@port}",
        body: JSON.dump(@send_body),
        headers: headers,
        idempotent: true,
        retry_limit: 5,
        retry_interval: 1
      )

      self
    end

    def response
      raise "Must `call` first" if @response.nil?
      @response
    end

    def success?
      response&.status.to_s.start_with?("2")
    end

    def fail?
      !success?
    end

    def as_json
      JSON.parse(body || "")
    rescue JSON::ParserError => e
      io.warn "Body: #{body}"
      io.warn "Code: #{response&.status}"
      io.warn "Headers: #{response&.headers.inspect}"
      io.warn "x-extra-info: #{CGI.unescape(response&.headers&.[]("x-extra-info") || "")}"
      raise e
    end

    def body
      response&.body
    end

    def headers
      {
        "Content-Type" => "application/json",
        "ce-id" => "MyFunction-#{SecureRandom.hex(10)}",
        "ce-time" => "2020-09-03T20:56:28.297915Z",
        "ce-type" => "",
        "ce-source" => "",
        "ce-sfcontext" => sfcontext,
        "Authorization" => "",
        "ce-specversion" => @spec_version,
        "ce-sffncontext" => ssfcontext
      }
    end

    def ssfcontext
      marshal_hash(raw_ssfcontext)
    end

    def raw_ssfcontext
      {
        "resource" => "",
        "requestId" => "",
        "accessToken" => "",
        "apexClassId" => nil,
        "apexClassFQN" => nil,
        "functionName" => "",
        "functionInvocationId" => nil
      }
    end

    def raw_sfcontext
      {
        "apiVersion" => "",
        "payloadVersion" => "",
        "userContext" =>
         {
           "orgId" => "",
           "userId" => "",
           "username" => "",
           "orgDomainUrl" => "",
           "onBehalfOfUserId" => nil,
           "salesforceBaseUrl" => ""
         }
      }
    end

    def sfcontext
      marshal_hash(raw_sfcontext)
    end

    def marshal_hash(value)
      Base64.strict_encode64(JSON.dump(value)).chomp
    end
  end
end
