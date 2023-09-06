class Api::Ubcseit::CourseSectionsController < Api::Ubcseit::AdminBaseApiController

  def get_course_sections
    # Get all course sections for a course (from the database; this doesn't consider the roster's assigned sections).
    # params[:course_name] is required - the name of the course
    # Returns a dictionary in the format:
    # {"course_display_name": "Some Course",
    #  "course_name": "somecourse",
    #  "sections": [{"days_code": 42,
    #                "end_time": "15:00:00",
    #                "is_lecture": True,
    #                "name": "A",
    #                "start_time": "13:00:00"},...
    #              ]
    # }
    # Sections are sorted by days_code, then start_time, then end_time.

    course = get_course_from_param
    sections_arr = UbCourseSection.where(course: course)
                                  .order(:days_code, :start_time, :end_time)
                                  .map { |section| section.to_h }

    respond_with_hash({
                        :course_name => course.name,
                        :course_display_name => course.display_name,
                        :sections => sections_arr
                      })
  end

end