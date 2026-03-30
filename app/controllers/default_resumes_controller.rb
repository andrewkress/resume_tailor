class DefaultResumesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_default_resume, only: [ :show, :edit, :update, :update_markdown ]

  def show
    @default_resume = current_user.default_resume
  end

  def new
    @default_resume = current_user.default_resume || current_user.default_resume.new
  end

  def edit
    @default_resume = current_user.default_resume
  end

  def create
    @default_resume = current_user.default_resume || current_user.default_resume.new
    @default_resume.markdown = params[:default_resume][:markdown] if params[:default_resume][:markdown]
    @default_resume.status = params[:default_resume][:status] if params[:default_resume][:status]

    # Attach file if present
    if params[:default_resume][:default_pdf]
      @default_resume.default_pdf.attach(params[:default_resume][:default_pdf])

      # Convert uploaded file to markdown if no markdown provided
      if @default_resume.markdown.blank?
        markdown = extract_markdown_from_file(@default_resume.default_pdf)
        @default_resume.markdown = markdown
      end
    end

    if @default_resume.save
      # Delete any existing active default resume
      current_user.default_resume.destroy rescue nil
      redirect_to resumes_path, notice: "Default resume created successfully."
    else
      redirect_to new_default_resume_path, alert: "Default resume could not be created: #{@default_resume.errors.full_messages.join(', ')}."
    end
  end

  def update
    @default_resume.markdown = params[:default_resume][:markdown] if params[:default_resume][:markdown]
    @default_resume.status = params[:default_resume][:status] if params[:default_resume][:status]

    # Attach file if present
    if params[:default_resume][:default_pdf]
      @default_resume.default_pdf.attach(params[:default_resume][:default_pdf])

      # Convert uploaded file to markdown if no markdown provided
      if @default_resume.markdown.blank?
        markdown = extract_markdown_from_file(@default_resume.default_pdf)
        @default_resume.markdown = markdown
      end
    end

    if @default_resume.save
      redirect_to resumes_path, notice: "Default resume updated successfully."
    else
      redirect_to edit_default_resume_path(@default_resume), alert: "Default resume could not be updated: #{@default_resume.errors.full_messages.join(', ')}."
    end
  end

  def update_markdown
    if @default_resume.update(default_resume_params.permit(:markdown, :status))
      redirect_to edit_default_resume_path(@default_resume), notice: "Markdown updated successfully."
    else
      redirect_to edit_default_resume_path(@default_resume), alert: "Could not update markdown."
    end
  end

  private

  def set_default_resume
    @default_resume = current_user.default_resume
  rescue ActiveRecord::RecordNotFound
    redirect_to resumes_path, alert: "Default resume not found."
  end

  def default_resume_params
    params.require(:default_resume).permit(:markdown, :status, :default_pdf)
  end

  def extract_markdown_from_file(file)
    # Use the same extractor as the resume job
    ResumeTextExtractor.new(file).extract
  rescue => e
    Rails.logger.error "Error extracting markdown from file: #{e.message}"
    ""
  end
end
