##
# The Home Controller houses (ha) any action that's available to the general public.
#
class HomeController < ApplicationController
  # If we wanted to require logging in to view the contact page, we could do this:
  # skip_before_action :authenticate_user!, except: [:publicSignUp, :contact]
  # But the info is already public on Github for the most part
  skip_before_action :authenticate_user!, except: [:publicSignUp]
  skip_before_action :set_course
  skip_before_action :authorize_user_for_course
  skip_before_action :authenticate_for_action
  skip_before_action :update_persistent_announcements

  def developer_login
    return unless request.post?

    user = User.find_by(email: params[:email])
    if user
      sign_in :user, user
      redirect_to("/") && return
    else
      flash[:error] = "User with Email: '#{params[:email]}' doesn't exist"
      redirect_to("/home/developer_login") && return
    end
  end

  # https://autolab.cs.cmu.edu/home/publicSignUp?id={#course_id}
  # where {#course_id} is the id of the public course a user wants to register
  #
  # This currently isn't in use, but if we reenable it, SWITCH TO snake_case PLEASE!
  def publicSignUp
    course_id = params[:id].to_i
    # for now, only check if this id is PUBLIC_COURSE_ID or ACM_COURSE_ID
    if course_id != PUBLIC_COURSE_ID && course_id != ACM_COURSE_ID
      flash[:error] = "Public course doesn't exist. Please check your link again."
      redirect_to(controller: "home", action: "index") && return
    end

    @course = Course.find(course_id)
    cud = @course.course_user_data.find_or_initialize_by(user: current_user)

    # allows user to be an instructor for demo course only
    cud.instructor = params[:isInstructor] if course_id == PUBLIC_COURSE_ID
    if cud.save
      flash[:success] = "You have successfully registered for #{@course.full_name}"
      redirect_to(controller: "course", course: @course.name,
                  action: "index") && return
    else
      flash[:error] = "An internal error occurred. Please contact the " \
                    "Autolab Development team at the " \
                    "contact link below"
      redirect_to(controller: "home", action: "index") && return
    end
  end

  def contact
    # --- empty ---
    # This route just renders the home#contact page, nothing special
  end

  def error_404; end

  def error_500; end
end
