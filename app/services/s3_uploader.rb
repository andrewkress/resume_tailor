class S3Uploader
  def initialize(file, key)
    @file = file
    @key = key
    @s3 = Aws::S3::Client.new(region: ENV['AWS_REGION'])
    @bucket = ENV['AWS_S3_BUCKET']
  end

  def upload
    @s3.put_object(
      bucket: @bucket,
      key: @key,
      body: @file,
      content_type: 'application/pdf'
    )

    presigned_url = @s3.generate_presigned_url(
      operation_name: 'GetObject',
      params: {
        bucket: @bucket,
        key: @key,
        response_content_disposition: 'attachment; filename="optimized_resume.pdf"',
        expires: 1.hour.to_i
      }
    )
    { url: presigned_url, key: @key }
  end
end
