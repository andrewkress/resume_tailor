require "test_helper"

class ResumeTest < ActiveSupport::TestCase
  test "resume is valid without an uploaded file when a profile default exists" do
    user = users(:default_user)
    user.default_pdf.attach(
      io: StringIO.new("default resume"),
      filename: "default.pdf",
      content_type: "application/pdf"
    )

    resume = user.resumes.new(job_description: "Build products", status: "pending")

    assert_predicate resume, :valid?
  end

  test "resume requires an uploaded file when no profile default exists" do
    user = users(:user_for_resume_tests)
    resume = user.resumes.new(job_description: "Build products", status: "pending")

    assert_not resume.valid?
    assert_includes resume.errors[:original_file], "must be uploaded unless you have a default resume on your profile"
  end

  test "snapshot_optimization_source uses the profile default first" do
    user = users(:default_user)
    user.default_pdf.attach(
      io: StringIO.new("default resume"),
      filename: "default.pdf",
      content_type: "application/pdf"
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

    resume.snapshot_optimization_source!
    resume.reload

    assert_equal "default_pdf", resume.optimization_source_kind
    assert_equal "default.pdf", resume.optimization_source_attachment.filename.to_s
    assert_equal "Profile default resume", resume.optimization_source_label
  end

  test "snapshot_optimization_source falls back to the uploaded file" do
    user = users(:user_for_resume_tests)
    resume = user.resumes.create!(
      job_description: "Build products",
      status: "pending",
      original_file: {
        io: StringIO.new("uploaded resume"),
        filename: "uploaded.pdf",
        content_type: "application/pdf"
      }
    )

    resume.snapshot_optimization_source!
    resume.reload

    assert_equal "uploaded_file", resume.optimization_source_kind
    assert_equal "uploaded.pdf", resume.optimization_source_attachment.filename.to_s
    assert_equal "Uploaded resume", resume.optimization_source_label
  end
end
