require "test_helper"

class ResumeAccessTest < ActionDispatch::IntegrationTest
  setup do
    @current_user = users(:default_user)
    @other_user = users(:user_for_another_test)

    @other_resume = @other_user.resumes.create!(
      job_description: "Confidential role",
      status: "completed",
      original_file: {
        io: StringIO.new("other user's uploaded resume"),
        filename: "other_resume.pdf",
        content_type: "application/pdf"
      }
    )

    @other_optimized_resume = @other_resume.optimized_resumes.create!(
      markdown: "Other user's tailored resume",
      model_used: "manual_edit"
    )
  end

  test "show returns not found for another users resume" do
    sign_in @current_user

    get resume_path(@other_resume)

    assert_response :not_found
  end

  test "regenerate returns not found for another users resume" do
    sign_in @current_user

    assert_no_difference("OptimizedResume.count") do
      post regenerate_resume_path(@other_resume), params: { model: "sonnet_4_6" }
    end

    assert_response :not_found
  end

  test "optimized resume edit returns not found for another users resume" do
    sign_in @current_user

    get edit_optimized_resume_path(@other_optimized_resume)

    assert_response :not_found
  end

  test "optimized resume update returns not found for another users resume" do
    sign_in @current_user

    assert_no_difference("OptimizedResume.count") do
      patch optimized_resume_path(@other_optimized_resume), params: {
        optimized_resume: { markdown: "Attempted overwrite" }
      }
    end

    assert_response :not_found
    assert_equal "Other user's tailored resume", @other_optimized_resume.reload.markdown
  end

  test "optimized resume destroy returns not found for another users resume" do
    sign_in @current_user

    assert_no_difference("OptimizedResume.count") do
      delete optimized_resume_path(@other_optimized_resume)
    end

    assert_response :not_found
    assert OptimizedResume.exists?(@other_optimized_resume.id)
  end
end
