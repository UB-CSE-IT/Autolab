class Api::Ubcseit::AdminBaseApiController < Api::V1::BaseApiController

  # This API controller is intended to be extended by CSE IT staff. It requires the admin_all scope.

  # Require the admin scope for all actions in this controller
  before_action -> { require_privilege :admin_all }

  # Don't set the course or attempt to authorize the user for the course for any actions in this controller
  skip_before_action :set_course
  skip_before_action :authorize_user_for_course

  # Helper methods below; these aren't routed

  def get_user_from_email_param
    # A helper method to read the request's email parameter and return the corresponding user or raise an ApiError.
    unless params[:email].present?
      raise ApiError.new("Required parameter 'email' not found.", :bad_request)
    end

    user = User.find_by(email: params[:email])
    if user.nil?
      raise ApiError.new("There is no user with that email address.", :bad_request)
    end

    user
  end

  def get_course_from_param
    # A helper method to read the request's course_name parameter and return the corresponding course or raise an ApiError.
    unless params[:course_name].present?
      raise ApiError.new("Required parameter 'course_name' not found.", :bad_request)
    end

    course = Course.find_by(name: params[:course_name])
    if course.nil?
      raise ApiError.new("There is no course with that name.", :bad_request)
    end

    course
  end

  def get_assessment_from_param(course)
    # A helper method to read the request's assessment_name parameter and return the corresponding assessment or raise an ApiError.
    unless params[:assessment_name].present?
      raise ApiError.new("Required parameter 'assessment_name' not found.", :bad_request)
    end

    assessment = course.assessments.find_by(name: params[:assessment_name])
    if assessment.nil?
      raise ApiError.new("There is no assessment with that name.", :bad_request)
    end

    assessment
  end

end