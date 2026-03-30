class BedrockResumeMarkdownFormatter
  DEFAULT_MODEL = BedrockOptimizer::HAIKU_4_5

  def initialize(text, model: DEFAULT_MODEL, client: nil)
    @text = text.to_s
    @model = model
    @client = client || Aws::BedrockRuntime::Client.new(region: ENV["AWS_REGION"])
  end

  def format
    response = @client.invoke_model(
      model_id: @model,
      content_type: "application/json",
      accept: "application/json",
      body: request_body.to_json
    )

    parsed = JSON.parse(response.body.read)
    parsed.dig("content", 0, "text").to_s.strip
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
      Convert the following raw resume text into clean Markdown.

      Requirements:
      - Preserve the candidate's facts exactly
      - Do not invent or infer missing information
      - Use Markdown headings and bullet lists where appropriate
      - Keep contact information near the top
      - Normalize resume sections such as Summary, Experience, Education, Skills, Projects, and Certifications when present
      - Return only Markdown with no explanation

      RESUME TEXT:
      #{@text}
    PROMPT
  end
end
