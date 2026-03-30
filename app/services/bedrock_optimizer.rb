class BedrockOptimizer
  MODELS = {
    sonnet_4_6: "us.anthropic.claude-sonnet-4-6",
    haiku_4_5: "anthropic.claude-haiku-4-5-20251001-v1:0",
    gpt_oss_120: "openai.gpt-oss-120b-1:0",
    gpt_oss_20: "openai.gpt-oss-20b-1:0"
  }.freeze

  SONNET_4_6 = MODELS[:sonnet_4_6] # $3.00 per 1M tokens
  HAIKU_4_5 = MODELS[:haiku_4_5] # $1.00 per 1M tokens
  GPT_OSS_120 = MODELS[:gpt_oss_120] # $0.15 per 1M tokens
  GPT_OSS_20 = MODELS[:gpt_oss_20] # $0.07 per 1M tokens

  def optimize
    return "Invalid model selected" unless @model

    response = @client.invoke_model(
      model_id: @model,
      content_type: "application/json",
      accept: "application/json",
      body: request_body.to_json
    )

    parsed = JSON.parse(response.body.read)
    parsed.dig("content", 0, "text")
  end

  attr_reader :model_name

  def initialize(resume_text, job_description, model)
    @resume_text = resume_text
    @job_description = job_description
    model_key = model.to_sym
    @model = MODELS[model_key]
    @model_name = model_key
    @client = Aws::BedrockRuntime::Client.new(region: ENV["AWS_REGION"])
  end

  private

  def request_body
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

  def prompt
    <<~PROMPT
      You are an expert resume writer. Optimize the following résumé to best match the job description provided.

      Keep the same general structure and truthful content, but:
      - Tailor language and keywords to match the job description
      - Strengthen bullet points with measurable impact where possible
      - Ensure the most relevant experience is highlighted
      - Return ONLY the optimized résumé text, no commentary

      JOB DESCRIPTION:
      #{@job_description}

      RÉSUMÉ:
      #{@resume_text}
    PROMPT
  end
end
