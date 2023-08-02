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

end