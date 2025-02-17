##
# Attachments can be either assessment or course-specific.
# This controller handles both types, setting @is_assessment to distinguish the two
#
class AttachmentsController < ApplicationController
  # inherited from ApplicationController
  # this will also set an @is_assessment variable based on the result of is_assessment?
  before_action :set_assessment, if: :assessment?
  before_action :set_assessment_breadcrumb
  before_action :set_attachment, except: %i[index new create]

  # This page shouldn't really be used
  action_auth_level :index, :instructor
  def index
    @attachments = if @is_assessment
                     @assessment.attachments.ordered
                   else
                     @course.attachments.where(assessment_id: nil).ordered
                   end
  end

  action_auth_level :new, :instructor
  def new
    @attachment = Attachment.new
  end

  action_auth_level :create, :instructor
  def create
    @attachment = if @is_assessment
                    @course.attachments.new(assessment_id: @assessment.id)
                  else
                    @course.attachments.new
                  end

    if @attachment.update(attachment_params)
      flash[:success] = "Attachment created"
      redirect_to_index
    else
      error_msg = "Attachment create failed:"
      if !@attachment.valid?
        @attachment.errors.full_messages.each do |msg|
          error_msg += "<br>#{msg}"
        end
      else
        error_msg += "<br>Unknown error"
      end
      flash[:error] = error_msg
      flash[:html_safe] = true
      COURSE_LOGGER.log("Failed to create attachment: #{error_msg}")

      if @is_assessment
        redirect_to new_course_assessment_attachment_path(@course, @assessment)
      else
        redirect_to new_course_attachment_path(@course)
      end
    end
  end

  action_auth_level :show, :student
  def show
    if @cud.instructor? || @cud.course_assistant?
      # Always allow instructors and course assistants to view attachments
      allowed_to_view_attachment = true
    elsif !@attachment.released?
      # Students cannot view unreleased attachments no matter what
      allowed_to_view_attachment = false
    elsif @is_assessment && @assessment.use_ub_section_deadlines && @assessment.ub_attachments_only_when_can_submit?
      # This is an assessment (not course) attachment and the assessment is set to only allow viewing
      # attachments when the student can submit
      ub_course_section = UbCourseSection.by_cud(@cud, @assessment.use_ub_lectures?)
      aud = AssessmentUserDatum.get(@assessment.id, @cud.id)
      allowed_to_view_attachment = aud.can_submit?(Time.now, @cud, ub_course_section)[0]
    else
      allowed_to_view_attachment = true
    end

    if allowed_to_view_attachment
      begin
        attached_file = @attachment.attachment_file
        if attached_file.attached?
          log_attachment_access(@attachment)
          send_data attached_file.download, filename: @attachment.filename,
                    type: @attachment.mime_type
          return
        end

        old_attachment_path = Rails.root.join("attachments", @attachment.filename)
        if File.exist?(old_attachment_path)
          log_attachment_access(@attachment)
          send_file old_attachment_path, filename: @attachment.filename, type: @attachment.mime_type
          return
        else
          COURSE_LOGGER.log("No file attached to attachment '#{@attachment.name}'")
          flash[:error] = "No file attached to attachment '#{@attachment.name}'"
          redirect_to_index && return
        end
      rescue StandardError
        COURSE_LOGGER.log("Error viewing attachment '#{@attachment.name}'")
        flash[:error] = "Error viewing attachment '#{@attachment.name}'"
        redirect_to_index && return
      end
    end

    flash[:error] = "You are not allowed to view this attachment at this time"
    redirect_to_index
  end

  action_auth_level :edit, :instructor
  def edit; end

  action_auth_level :update, :instructor
  def update
    if @attachment.update(attachment_params)
      flash[:success] = "Attachment updated"
      redirect_to_index
    else
      error_msg = "Attachment update failed."
      @attachment.errors.full_messages.each do |msg|
        error_msg += "<br>#{msg}"
      end
      flash[:error] = error_msg
      flash[:html_safe] = true
      COURSE_LOGGER.log("Failed to update attachment: #{error_msg}")

      if @is_assessment
        redirect_to edit_course_assessment_attachment_path(@course, @assessment, @attachment)
      else
        redirect_to edit_course_attachment_path(@course, @attachment)
      end
    end
  end

  action_auth_level :destroy, :instructor
  def destroy
    @attachment.destroy
    flash[:success] = "Attachment deleted"
    redirect_to_index
  end

private

  def assessment?
    @is_assessment = params.key?(:assessment_name)
  end

  def set_attachment
    @attachment = if @is_assessment
                    @course.attachments.where(assessment_id: @assessment.id).friendly.find(
                      params[:id], allow_nil: true
                    )
                  else
                    @course.attachments.friendly.find(params[:id], allow_nil: true)
                  end

    return unless @attachment.nil?

    COURSE_LOGGER.log("Cannot find attachment with id: #{params[:id]}")
    flash[:error] = "Could not find Attachment \##{params[:id]}"
    redirect_to_index
  end

  def redirect_to_index
    if @is_assessment
      redirect_to course_assessment_path(@course, @assessment)
    else
      redirect_to course_path(@course)
    end
  end

  def attachment_params
    params.require(:attachment).permit(:name, :file, :category_name, :release_at, :mime_type)
  end

  def log_attachment_access(attachment)
    if @is_assessment && @cud.student?
      user = @cud.user.full_name_with_email
      ip_address = request.remote_ip
      ASSESSMENT_LOGGER.log("Attachment \"#{attachment.name}\" (#{attachment.filename}) was viewed by #{user} from #{ip_address}.")
    end
  end
end
