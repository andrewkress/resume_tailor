class ProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user

  def edit
    @user.build_default_resume unless @user.default_resume
  end

  def update
    @user.assign_attributes(profile_params)

    if @user.save
      redirect_to edit_profile_path, notice: "Profile updated successfully."
    else
      @user.build_default_resume unless @user.default_resume
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = current_user
  end

  def profile_params
    params.require(:user).permit(
      :first_name,
      :last_name,
      default_resume_attributes: [ :id, :markdown, :default_pdf ]
    )
  end
end
