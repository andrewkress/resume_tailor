class BedrockOptimizer
  MODELS = {
    sonnet_4_6: "us.anthropic.claude-sonnet-4-6",
    haiku_4_5: "us.anthropic.claude-haiku-4-5-20251001-v1:0",
    llama_4_maverick: "us.meta.llama4-maverick-17b-instruct-v1:0",
    llama_4_scout: "us.meta.llama4-scout-17b-instruct-v1:0",
    nova_2_lite: "us.amazon.nova-2-lite-v1:0",
    gpt_oss_120: "openai.gpt-oss-120b",
    gpt_oss_20: "openai.gpt-oss-20b"

  }.freeze

  SONNET_4_6 = MODELS[:sonnet_4_6] # $3.00 per 1M tokens
  HAIKU_4_5 = MODELS[:haiku_4_5] # $1.00 per 1M tokens
  LLAMA_4_MAVERICK = MODELS[:llama_4_maverick] # $0.24 per 1M tokens
  LLAMA_4_SCOUT = MODELS[:llama_4_scout] # $0.17 per 1M tokens
  NOVA_2_LITE = MODELS[:nova_2_lite] # $0.30 per 1M tokens
  GPT_OSS_120 = MODELS[:gpt_oss_120] # $0.15 per 1M tokens
  GPT_OSS_20 = MODELS[:gpt_oss_20] # $0.07 per 1M tokens

  def optimize
    return "Invalid model selected" unless @model

    raw_response = if @model.start_with?("openai.gpt")
      invoke_openai_model
    else
      invoke_bedrock_model
    end

    Windows1252Sanitizer.call(extract_text(raw_response))
  end

  def initialize(resume_text, job_description, model, client: nil)
    @resume_text = resume_text
    @job_description = job_description
    model_key = model.to_sym
    @model = MODELS[model_key]
    @model_name = model_key
    @client = client || (@model ? bedrock_client : nil)
  end

  private

  def bedrock_client
    return @bedrock_client if defined?(@bedrock_client)

    @bedrock_client = if @model.start_with?("openai.gpt")
      OpenAI::Client.new
    else
      Aws::BedrockRuntime::Client.new(region: ENV["AWS_REGION"])
    end
  end

  def invoke_bedrock_model
    response = @client.invoke_model(
      model_id: @model,
      content_type: "application/json",
      accept: "application/json",
      body: request_body.to_json
    )

    JSON.parse(response.body.read)
  end

  def invoke_openai_model
    @client.responses.create(**gpt_request_body)
  end

  def request_body
    return anthropic_request_body if @model.start_with?("us.anthropic")
    return llama_request_body if @model.start_with?("us.meta.llama")
    return nova_request_body if @model.start_with?("us.amazon.nova")

    raise "Unsupported model: #{@model}"
  end

  def nova_request_body
    {
      system: [
        {
          text: system_prompt
        }
      ],
      messages: [
        {
          role: "user",
          content: [
            {
              text: user_prompt
            }
          ]
        }
      ],
      inferenceConfig: {
        maxTokens: 4096,
        temperature: 0.5
      }
    }
  end

  def llama_request_body
    {
      prompt: llama_prompt,
      max_gen_len: 512,
      temperature: 0.5
    }
  end

  def anthropic_request_body
    {
      anthropic_version: "bedrock-2023-05-31",
      max_tokens: 4096,
      messages: [
        {
          role: "user",
          content: prompt
        }
      ]
    }
  end

  def gpt_request_body
    {
      model: @model,
      input: [
        {
          role: "system",
          content: system_prompt
        },
        {
          role: "user",
          content: user_prompt
        }
      ]
    }
  end

  def extract_text(parsed)
    if @model.start_with?("us.anthropic")
      parsed.dig("content", 0, "text").to_s.strip
    elsif @model.start_with?("us.meta.llama")
      parsed.fetch("generation", "").to_s.strip
    elsif @model.start_with?("us.amazon.nova")
      parsed.fetch("output", {})
        .fetch("message", {})
        .fetch("content", [])
        .filter_map { |item| item["text"] }
        .join("\n")
        .strip
    elsif @model.start_with?("openai.gpt")
      return parsed["output_text"].to_s.strip if parsed.is_a?(Hash)

      parsed.output_text.to_s.strip
    else
      raise "Unsupported model: #{@model}"
    end
  end

  def prompt
    <<~PROMPT
      #{system_prompt}

      JOB DESCRIPTION:
      #{@job_description}

      RÉSUMÉ:
      #{@resume_text}
    PROMPT
  end

  def system_prompt
    <<~PROMPT
      You are an expert resume writer. Optimize the following resume to best match the job description provided.

      Keep the same general structure and truthful content, but:
      - Tailor language and keywords to match the job description
      - Strengthen bullet points with measurable impact where possible
      - Ensure the most relevant experience is highlighted
      - Return ONLY the optimized résumé text, no commentary
    PROMPT
  end

  def user_prompt
    <<~PROMPT
      JOB DESCRIPTION:
      #{@job_description}

      RESUME:
      #{@resume_text}
    PROMPT
  end

  def llama_prompt
    <<~PROMPT
      <|begin_of_text|><|start_header_id|>system<|end_header_id|>
      #{system_prompt}<|eot_id|><|start_header_id|>user<|end_header_id|>
      #{user_prompt}<|eot_id|><|start_header_id|>assistant<|end_header_id|>
    PROMPT
  end
end
