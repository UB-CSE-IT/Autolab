class Api::Ubcseit::AdminCheckController < Api::Ubcseit::AdminBaseApiController

  def admin_check
    user = get_user_from_email_param
    respond_with_hash({ :email => params[:email], :is_administrator => user.administrator? })
  end

end