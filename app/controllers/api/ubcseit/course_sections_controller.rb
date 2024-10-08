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
    # Sections are sorted alphabetically by name.

    course = get_course_from_param
    sections_arr = UbCourseSection.where(course: course)
                                  .order(:name)
                                  .map { |section| section.to_h }

    respond_with_hash({
                        :course_name => course.name,
                        :course_display_name => course.display_name,
                        :sections => sections_arr
                      })
  end

  def upsert_course_sections

    course = get_course_from_param
    sections = params[:sections]

    sections.each do |section|
      UbCourseSection.create_or_update(
        course.name,
        section[:name],
        section[:is_lecture],
        section[:start_time],
        section[:end_time],
        section[:days_code])
    end

    respond_with_hash({
                        :course_name => course.name,
                        :course_display_name => course.display_name,
                        :success => true
                      })
  end

end