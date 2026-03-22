class ResumesController < ApplicationController
  before_action :authenticate_user!

  def index
    @resumes = current_user.resumes.order(created_at: :desc)

    # Calculate stats for dashboard
    total = @resumes.count
    completed = @resumes.count { |r| r.status == "completed" }
    processing = @resumes.count { |r| r.status == "processing" }
    failed = @resumes.count { |r| r.status == "failed" }
    @stats = {
      total: total,
      completed: completed,
      processing: processing,
      failed: failed
    }
  end

  def new
    @resume = Resume.new
  end

  def create
    @resume = current_user.resumes.build(resume_params)
    @resume.original_filename = params[:resume][:original_file]&.original_filename

    if @resume.save
      OptimizeResumeJob.perform_later(@resume.id)
      redirect_to @resume, notice: "Resume uploaded! Optimization is in progress."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @resume = current_user.resumes.find(params[:id])
  end

  private

  def resume_params
    params.require(:resume).permit(:job_description, :original_file)
  end
end
