class ResumesController < ApplicationController
  before_action :authenticate_user!

  def index
    @resumes = current_user.resumes.order(created_at: :desc)

    # Handle filter parameter
    filter = params[:filter]&.to_sym
    case filter
    when :completed
      @resumes = @resumes.where(status: "completed")
    when :processing
      @resumes = @resumes.where(status: "processing")
    when :failed
      @resumes = @resumes.where(status: "failed")
    else
      # Default: show all resumes
    end

    # Calculate stats for dashboard
    @resume_stats = current_user.resumes
    total = @resume_stats.count
    completed = @resume_stats.where(status: "completed").count
    processing = @resume_stats.where(status: "processing").count
    failed = @resume_stats.where(status: "failed").count
    @stats = {
      total: total,
      completed: completed,
      processing: processing,
      failed: failed
    }

    @filter = filter
  end

  def new
    @resume = Resume.new
  end

  def create
    @resume = current_user.resumes.build(resume_params)
    @resume.original_filename = params[:resume][:original_file]&.original_filename

    if @resume.save
      OptimizeResumeJob.perform_later(@resume.id, resume_params[:model])
      redirect_to @resume, notice: "Resume uploaded! Optimization is in progress."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @resume = current_user.resumes.find(params[:id])
  end

  def regenerate
    @resume = current_user.resumes.find(params[:id])
    latest_optimized_resume = @resume.optimized_resumes.order(created_at: :desc).first
    model = params[:model]&.to_sym || latest_optimized_resume&.model_used&.to_sym || :sonnet_4_6

    if latest_optimized_resume && model.to_s == latest_optimized_resume.model_used
      redirect_to @resume, alert: "Selected model is the same as the current model."
      return
    end

    OptimizeResumeJob.perform_later(@resume.id, model)
    redirect_to @resume, notice: "New optimization is in progress!"
  rescue => e
    redirect_to @resume || resumes_path, alert: "Optimization failed: #{e.message}"
  end

  private

  def resume_params
    params.require(:resume).permit(:job_description, :original_file, :model, :company_name, :application_link)
  end
end
