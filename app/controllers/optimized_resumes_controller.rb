class OptimizedResumesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_optimized_resume, only: [ :edit, :update, :destroy ]

  def edit; end

  def update
    new_optimized_resume = @resume.optimized_resumes.create!(
      markdown: optimized_resume_params[:markdown]
    )

    @resume.update!(status: "pending")
    GeneratePdfJob.perform_later(new_optimized_resume.id)

    redirect_to @resume, notice: "Optimized resume updated! A new PDF is being generated."
  end

  def destroy
    @optimized_resume.pdf.purge if @optimized_resume.pdf.attached?
    @optimized_resume.destroy
    redirect_to @resume, notice: "Optimized resume deleted."
  end

  private

  def set_optimized_resume
    @optimized_resume = OptimizedResume.find(params[:id])
    @resume = current_user.resumes.find(@optimized_resume.resume_id) # Ensure the optimized resume belongs to the current user

    redirect_to root_path, alert: "Resume not found" unless @resume
  end

  def optimized_resume_params
    params.require(:optimized_resume).permit(:markdown)
  end
end
