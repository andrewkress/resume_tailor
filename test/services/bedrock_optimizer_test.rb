require "test_helper"
require "stringio"

class BedrockOptimizerTest < ActiveSupport::TestCase
  test "uses anthropic request and response format" do
    client = bedrock_client_stub(response_body: { content: [ { text: "Optimized resume" } ] }) do |payload|
      assert_equal BedrockOptimizer::HAIKU_4_5, payload[:model_id]

      body = JSON.parse(payload[:body])
      assert_equal "bedrock-2023-05-31", body["anthropic_version"]
      assert_equal 4096, body["max_tokens"]
      assert_equal "user", body.dig("messages", 0, "role")
      assert_includes body.dig("messages", 0, "content"), "JOB DESCRIPTION:"
      assert_includes body.dig("messages", 0, "content"), "RÉSUMÉ:"
    end

    optimizer = BedrockOptimizer.new("Resume text", "Job description", :haiku_4_5, client: client)

    assert_equal "Optimized resume", optimizer.optimize
  end

  test "sanitizes unsupported characters from model output" do
    client = bedrock_client_stub(response_body: {
      content: [ { text: "Built features\u2009with care \u2713" } ]
    })

    optimizer = BedrockOptimizer.new("Resume text", "Job description", :haiku_4_5, client: client)

    assert_equal "Built features with care *", optimizer.optimize
  end

  test "uses llama native request and response format" do
    client = bedrock_client_stub(response_body: { generation: "Tailored output" }) do |payload|
      assert_equal BedrockOptimizer::LLAMA_4_SCOUT, payload[:model_id]

      body = JSON.parse(payload[:body])
      assert_equal 512, body["max_gen_len"]
      assert_equal 0.5, body["temperature"]
      assert_includes body["prompt"], "<|start_header_id|>system<|end_header_id|>"
      assert_includes body["prompt"], "<|start_header_id|>user<|end_header_id|>"
      assert_includes body["prompt"], "JOB DESCRIPTION:"
      assert_includes body["prompt"], "RESUME:"
    end

    optimizer = BedrockOptimizer.new("Resume text", "Job description", :llama_4_scout, client: client)

    assert_equal "Tailored output", optimizer.optimize
  end

  test "uses nova native request and response format" do
    client = bedrock_client_stub(response_body: {
      output: {
        message: {
          content: [
            { text: "Tailored line 1" },
            { text: "Tailored line 2" }
          ]
        }
      }
    }) do |payload|
      assert_equal BedrockOptimizer::NOVA_2_LITE, payload[:model_id]

      body = JSON.parse(payload[:body])
      assert_includes body.dig("system", 0, "text"), "You are an expert resume writer."
      assert_equal "user", body.dig("messages", 0, "role")
      assert_includes body.dig("messages", 0, "content", 0, "text"), "JOB DESCRIPTION:"
      assert_includes body.dig("messages", 0, "content", 0, "text"), "RESUME:"
      assert_equal 4096, body.dig("inferenceConfig", "maxTokens")
      assert_equal 0.5, body.dig("inferenceConfig", "temperature")
    end

    optimizer = BedrockOptimizer.new("Resume text", "Job description", :nova_2_lite, client: client)

    assert_equal "Tailored line 1\nTailored line 2", optimizer.optimize
  end

  private

  def bedrock_client_stub(response_body:)
    stub(invoke_model: lambda do |**payload|
      yield payload if block_given?
      stub(body: StringIO.new(response_body.to_json))
    end)
  end
end
