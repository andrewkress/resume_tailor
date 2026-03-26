class BedrockOptimizer
  MODEL_ID = "us.anthropic.claude-sonnet-4-6"

  def initialize(resume_text, job_description)
    @resume_text = resume_text
    @job_description = job_description
    @client = Aws::BedrockRuntime::Client.new(region: ENV["AWS_REGION"])
  end

  def optimize
    response = @client.invoke_model(
      model_id: MODEL_ID,
      content_type: "application/json",
      accept: "application/json",
      body: request_body.to_json
    )

    parsed = JSON.parse(response.body.read)
    parsed.dig("content", 0, "text")
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
