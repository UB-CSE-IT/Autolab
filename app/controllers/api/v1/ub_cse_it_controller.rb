class Api::V1::UbCseItController < Api::V1::BaseApiController

  before_action -> { require_privilege :admin_all }

  skip_before_action :set_course
  skip_before_action :authorize_user_for_course

  def admin_check
    if !params.has_key?(:email)
      raise ApiError.new("Required parameter 'email' not found.", :bad_request)
    end

    user = User.find_by(email: params[:email])
    if user.nil?
      raise ApiError.new("There is no user with that email address.", :bad_request)
    end

    respond_with_hash({ :email => params[:email], :is_administrator => user.administrator? })
  end

end