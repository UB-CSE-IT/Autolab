class Api::Ubcseit::GradingAssignmentsController < Api::Ubcseit::AdminBaseApiController

  # This controller is used by the Autolab Self-Service Portal's random grading TA assignment tool

  def get_user_courses
    # Returns a list of courses that the user is enrolled in, along with their role in each course.
    # params[:email] is required - the email address of the user to look up
    # The email acts as a permission check, this will only return courses that the user is enrolled in.
    # Returns a JSON object with the following structure:
    # {
    #   "email": "user@buffalo.edu",
    #   "courses": [
    #     {
    #       "name": "course1",  # The technical name of the course
    #       "display_name": "Course 1",  # The display name of the course
    #       "semester": "f23", # The semester code of the course
    #       "auth_level": "student",  # or "instructor" or "course_assistant"
    #     }, ...
    #   ],
    # }
    # Courses are sorted by end_date, so the most recent course is last.

    user = get_user_from_email_param
    uid = user.id
    courses_for_user = User.courses_for_user(user)
    courses = []

    courses_for_user.order(:end_date).each do |course|
      course_hash = course.as_json(only: [:name, :display_name, :semester])
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

  def get_assessment_submissions
    # Returns a hash with a list of submissions for a given assessment.
    # Only the latest submission for each STUDENT is included. (CAs and Instructors are not included.
    # Some students may not have submitted anything, so they will not be included.)
    # params[:course_name] is required - the name of the course
    # params[:assessment_name] is required - the name of the assessment
    # There is no permission check here - the developer must ensure that the user has permission to access this.
    # Returns a JSON object with the following structure:
    # {
    #   "course_name": "course1",  # The technical name of the course
    #   "assessment_name": "assessment1",  # The technical name of the assessment
    #   "submissions": [
    #     {
    #       "email": "somebody@buffalo.edu",
    #       "display_name": "First Last"
    #       "version": 22
    #       "url": "https://autolab.cse.buffalo.edu/courses/cse-it-test-course/assessments/pdftest/submissions/22/view",
    #       "graded": true, # For future use, not implemented yet.
    #     }, ...
    #   ],
    # }
    # Submissions are sorted alphabetically by email address.

    course = get_course_from_param
    assessment = get_assessment_from_param(course)
    latest_submissions = assessment.assessment_user_data
                                   .includes(course_user_datum: :user)
                                   .where(course_user_data: { instructor: false, course_assistant: false })
                                   .order("users.email ASC")
                                   .map(&:latest_submission)
                                   .reject(&:nil?)

    ret_submissions = []

    latest_submissions.each do |submission|

      submission_hash = {
        email: submission.course_user_datum.user.email,
        display_name: submission.course_user_datum.user.display_name,
        version: submission.version,
        url: view_course_assessment_submission_url(course, assessment, submission),
        graded: false, # TODO implement this; needs more planning. Probably check if there are any annotations
      }

      ret_submissions << submission_hash
    end

    ret = {
      course_name: course.name,
      assessment_name: assessment.name,
      submissions: ret_submissions
    }

    respond_with_hash(ret)
  end

  def get_course_assessments
    # Returns a hash with a list of assessments for a given course.
    # params[:course_name] is required - the name of the course
    # There is no permission check here - the developer must ensure that the user has permission to access this.
    # Returns a JSON object with the following structure:
    # {
    #   "course_name": "course1",  # The technical name of the course
    #   "display_name": "Course 1",  # The display name of the course
    #   "assessments": [
    #     {
    #       "name": "assessment1",  # The technical name of the assessment
    #       "display_name": "Assessment 1",  # The display name of the assessment
    #       "url": "https://autolab.cse.buffalo.edu/courses/cse-it-test-course/assessments/pdftest",
    #     }, ...
    #   ],
    # }
    # Assessments are sorted by due date, with the earliest due date first.

    course = get_course_from_param
    assessments = course.assessments

    ret_assessments = []

    assessments.order(:due_at).each do |assessment|
      assessment_hash = assessment.as_json(only: [:name, :display_name])
      assessment_hash[:url] = course_assessment_url(course, assessment)
      ret_assessments << assessment_hash
    end

    ret = {
      course_name: course.name,
      display_name: course.display_name,
      assessments: ret_assessments,
    }

    respond_with_hash(ret)
  end

  def get_course_users
    # Returns a hash with a list of users for a given course.
    # params[:course_name] is required - the name of the course
    # There is no permission check here - the developer must ensure that the user has permission to access this.
    # Returns a JSON object with the following structure:
    # {
    #   "course_name": "course1",  # The technical name of the course
    #   "display_name": "Course 1",  # The display name of the course
    #   "users": [
    #     {
    #       "email": "example@buffalo.edu",
    #       "display_name": "First Last",
    #       "role": "student", # or "instructor" or "course_assistant"
    #     }, ...
    #   ],
    # }
    # Users are sorted alphabetically by email address.

    course = get_course_from_param

    ret_users = []

    course.course_user_data.joins(:user).order("users.email ASC").each do |cud|
      user = cud.user
      user_hash = {
        email: user.email,
        display_name: user.display_name,
        role: cud.auth_level_string,
      }
      ret_users << user_hash
    end

    ret = {
      course_name: course.name,
      display_name: course.display_name,
      users: ret_users,
    }

    respond_with_hash(ret)
  end

end