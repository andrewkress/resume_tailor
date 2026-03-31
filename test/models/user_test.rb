require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "destroys associated resumes when the user is destroyed" do
    user = User.create!(
      email: "cascade_test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    resume = user.resumes.create!(
      job_description: "Build products",
      status: "pending",
      original_file: {
        io: StringIO.new("uploaded resume"),
        filename: "uploaded.pdf",
        content_type: "application/pdf"
      }
    )

    assert_difference("Resume.count", -1) do
      user.destroy!
    end

    assert_not Resume.exists?(resume.id)
  end

  test "can attach a default resume" do
    user = users(:default_user)

    user.default_pdf.attach(
      io: StringIO.new("default resume"),
      filename: "default.pdf",
      content_type: "application/pdf"
    )

    assert user.default_pdf.attached?
    assert_equal "default.pdf", user.default_pdf.filename.to_s
  end
end
