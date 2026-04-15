class ResumesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_resume, only: [ :show, :destroy, :regenerate ]

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
    @resume = current_user.resumes.build(resume_params.except(:model))
    @resume.original_filename = params[:resume][:original_file]&.original_filename

    if @resume.save
      @resume.snapshot_optimization_source!
      OptimizeResumeJob.perform_later(@resume.id, resume_params[:model])
      redirect_to @resume, notice: "Resume uploaded! Optimization is in progress."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show; end

  def destroy
    @resume.destroy
    redirect_to resumes_path, notice: "Resume was successfully deleted."
  end

  def regenerate
    latest_optimized_resume = @resume.optimized_resumes.order(created_at: :desc).first
    model = params[:model]&.to_sym || latest_optimized_resume&.model_used&.to_sym || :sonnet_4_6

    if latest_optimized_resume && model.to_s == latest_optimized_resume.model_used
      redirect_to @resume, alert: "Selected model is the same as the current model."
      return
    end

    OptimizeResumeJob.perform_later(@resume.id, model)
    redirect_to @resume, notice: "New optimization is in progress!"
  rescue => _e
    redirect_to @resume || resumes_path, alert: "Optimization failed"
  end

  private

  def set_resume
    @resume = current_user.resumes.find(params[:id])
    redirect_to root_path, alert: "Resume not found" unless @resume
  end

  def resume_params
    params.require(:resume).permit(:job_description, :original_file, :model, :company_name, :application_link)
  end
end
