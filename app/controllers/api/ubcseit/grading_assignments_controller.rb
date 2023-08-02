class Api::Ubcseit::GradingAssignmentsController < Api::Ubcseit::AdminBaseApiController

  # This controller is used by the Autolab Self-Service Portal's random grading TA assignment tool

  def get_user_courses
    # Returns a list of courses that the user is enrolled in, along with their role in each course.
    # params[:email] is required - the email address of the user to look up
    # Returns a JSON object with the following structure:
    # {
    #   "email": "user@buffalo.edu",
    #   "courses": [
    #     {
    #       "name": "course1",  # The technical name of the course
    #       "display_name": "Course 1",  # The display name of the course
    #       "auth_level": "student",  # or "instructor" or "course_assistant"
    #     }, ...
    # ]
    user = get_user_from_email_param
    uid = user.id
    courses_for_user = User.courses_for_user(user)
    courses = []

    courses_for_user.each do |course|
      course_hash = course.as_json(only: [:name, :display_name])
      cud = CourseUserDatum.find_cud_for_course(course, uid)
      course_hash[:role] = cud.auth_level_string
      courses << course_hash
    end

    ret = {
      email: user.email,
      courses: courses
    }

    respond_with_hash(ret)
  end

end