module UbCourseSectionsHelper
  def get_course_user_section(course_user_datum, lecture_section = false)
    # Return a UbCourseSection for the given course_user_datum. Nil if none exists.
    # Set lecture_section to true to get the lecture section instead of the lab/rec section.

    section_name = lecture_section ? course_user_datum.lecture : course_user_datum.section
    if section_name.nil? || section_name.empty?
      return nil
    end

    course = course_user_datum.course

    UbCourseSection.where(course: course, name: section_name, is_lecture: lecture_section).first
  end

  def section_can_submit_at_time(course_user_section, time)
    if course_user_section.nil?
      # Do not allow submissions if the user is not in a section
      return false
    end

    return true # TODO: implement this
  end

end
