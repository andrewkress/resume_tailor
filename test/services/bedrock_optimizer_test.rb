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

  test "uses openai responses api format" do
    responses_api = stub(create: lambda do |parameters: nil, **kwargs|
      payload = parameters || kwargs

      assert_equal BedrockOptimizer::GPT_OSS_20, payload[:model]
      assert_equal "system", payload.dig(:input, 0, :role)
      assert_includes payload.dig(:input, 0, :content), "You are an expert resume writer."
      assert_equal "user", payload.dig(:input, 1, :role)
      assert_includes payload.dig(:input, 1, :content), "JOB DESCRIPTION:"
      assert_includes payload.dig(:input, 1, :content), "RESUME:"

      { "output_text" => "OpenAI tailored resume" }
    end)

    client = stub(responses: responses_api)
    optimizer = BedrockOptimizer.new("Resume text", "Job description", :gpt_oss_20, client: client)

    assert_equal "OpenAI tailored resume", optimizer.optimize
  end

  test "preserves unicode hyphen variants from openai output" do
    responses_api = stub(create: lambda do |parameters: nil, **kwargs|
      { "output_text" => "Built customer\u2011facing tools" }
    end)

    client = stub(responses: responses_api)
    optimizer = BedrockOptimizer.new("Resume text", "Job description", :gpt_oss_20, client: client)

    assert_equal "Built customer-facing tools", optimizer.optimize
  end

  test "uses zai glm-5 request and response format" do
    client = bedrock_client_stub(response_body: {
      choices: [
        { message: { content: "GLM-5 optimized resume" } }
      ]
    }) do |payload|
      assert_equal BedrockOptimizer::GLM_5, payload[:model_id]

      body = JSON.parse(payload[:body])
      assert_equal "zai.glm-5", body["model"]
      assert_equal "user", body.dig("messages", 0, "role")
      assert_includes body.dig("messages", 0, "content"), "JOB DESCRIPTION:"
      assert_includes body.dig("messages", 0, "content"), "RÉSUMÉ:"
    end

    optimizer = BedrockOptimizer.new("Resume text", "Job description", :glm_5, client: client)

    assert_equal "GLM-5 optimized resume", optimizer.optimize
  end

  private

  def bedrock_client_stub(response_body:)
    stub(invoke_model: lambda do |**payload|
      yield payload if block_given?
      stub(body: StringIO.new(response_body.to_json))
    end)
  end
end
