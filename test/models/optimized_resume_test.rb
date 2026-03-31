require "test_helper"

class OptimizedResumeTest < ActiveSupport::TestCase
  test "is valid with markdown and an allowed model" do
    optimized_resume = OptimizedResume.new(
      resume: resumes(:one),
      markdown: "Tailored resume text",
      model_used: OptimizedResume::MODELS.first
    )

    assert_predicate optimized_resume, :valid?
  end

  test "is valid with manual_edit as the model" do
    optimized_resume = OptimizedResume.new(
      resume: resumes(:one),
      markdown: "Tailored resume text",
      model_used: "manual_edit"
    )

    assert_predicate optimized_resume, :valid?
  end

  test "requires markdown" do
    optimized_resume = OptimizedResume.new(
      resume: resumes(:one),
      markdown: nil,
      model_used: OptimizedResume::MODELS.first
    )

    assert_not optimized_resume.valid?
    assert_includes optimized_resume.errors[:markdown], "can't be blank"
  end

  test "rejects a model outside the allowlist" do
    optimized_resume = OptimizedResume.new(
      resume: resumes(:one),
      markdown: "Tailored resume text",
      model_used: "not_a_real_model"
    )

    assert_not optimized_resume.valid?
    assert_includes optimized_resume.errors[:model_used], "is not included in the list"
  end

  test "allows model_used to be nil" do
    optimized_resume = OptimizedResume.new(
      resume: resumes(:one),
      markdown: "Tailored resume text",
      model_used: nil
    )

    assert_predicate optimized_resume, :valid?
  end

  test "can attach a generated pdf" do
    optimized_resume = OptimizedResume.create!(
      resume: resumes(:one),
      markdown: "Tailored resume text",
      model_used: "manual_edit"
    )

    optimized_resume.pdf.attach(
      io: StringIO.new("pdf content"),
      filename: "tailored_resume.pdf",
      content_type: "application/pdf"
    )

    assert optimized_resume.pdf.attached?
    assert_equal "tailored_resume.pdf", optimized_resume.pdf.filename.to_s
  end
end
