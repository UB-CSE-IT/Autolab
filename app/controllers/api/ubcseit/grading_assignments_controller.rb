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
    #   ],
    # }
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

    course = get_course_from_param
    assessment = get_assessment_from_param(course)
    latest_submissions = assessment.assessment_user_data
                                   .map(&:latest_submission)
                                   .reject(&:nil?)

    ret_submissions = []

    latest_submissions.each do |submission|
      submitter_cud = submission.course_user_datum
      submitter = submitter_cud.user
      if submitter_cud.has_auth_level?(:course_assistant)
        next # Only include submissions from students
      end

      submission_hash = {
        email: submitter.email,
        display_name: submitter.display_name,
        version: submission.version,
        url: view_course_assessment_submission_url(course, assessment, submission),
        graded: false, # TODO implement this; needs more planning
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

end # Class