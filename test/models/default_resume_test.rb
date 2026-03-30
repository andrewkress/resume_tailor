require "test_helper"

class DefaultResumeTest < ActiveSupport::TestCase
  test "enforces one default resume per user" do
    user = User.create!(email: "default-resume@example.com", password: "password123")
    DefaultResume.create!(user: user, markdown: "# Resume")

    duplicate = DefaultResume.new(user: user, markdown: "# Another Resume")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already been taken"
  end

  test "populates markdown from an attached file after commit" do
    user = User.create!(email: "attached-default-resume@example.com", password: "password123")
    default_resume = DefaultResume.new(user: user)

    default_resume.default_pdf.attach(
      io: StringIO.new("%PDF-1.4 test"),
      filename: "resume.pdf",
      content_type: "application/pdf"
    )

    ResumeTextExtractor.stub(:new, stub(extract: "# Resume")) do
      default_resume.save!
    end

    assert_equal "# Resume", default_resume.reload.markdown
  end
end
