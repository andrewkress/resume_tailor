class DashboardController < ApplicationController
  before_action :authenticate_user!
  def index
    redirect_to resumes_path
  end
end
