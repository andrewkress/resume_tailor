require "test_helper"

class DefaultResumeTest < ActiveSupport::TestCase
  test "enforces one default resume per user" do
    user = User.create!(email: "default-resume@example.com", password: "password123")
    DefaultResume.create!(user: user, markdown: "# Resume")

    duplicate = DefaultResume.new(user: user, markdown: "# Another Resume")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already been taken"
  end
end
