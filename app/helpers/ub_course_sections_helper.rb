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

    current_day_name = time.strftime("%A") # e.g. "Monday"
    day_allowed = day_name_included_in_bit_code?(current_day_name, course_user_section.days_code)
    unless day_allowed
      return false
    end



    return true # TODO: implement this
  end

  def day_name_to_bit_code(day_name)
    # Convert a day name to a bit code as it would be represented in the database.
    case day_name
    when "Sunday"
      1
    when "Monday"
      2
    when "Tuesday"
      4
    when "Wednesday"
      8
    when "Thursday"
      16
    when "Friday"
      32
    when "Saturday"
      64
    else
      0
    end
  end

  def day_name_included_in_bit_code?(day_name, bit_code)
    # Check if a day name is included in a bit code as it would be represented in the database.
    day_name_to_bit_code(day_name) & bit_code != 0
  end

  def days_bit_code_to_english(bit_code)
    # Convert a bit code as it would be represented in the database to a string in English.
    # e.g. 2 => "Monday"
    #      6 => "Monday, Tuesday"
    #      127 => "Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, Saturday"
    day_names = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]
    day_names.select { |day_name| day_name_included_in_bit_code?(day_name, bit_code) }.join(", ")
  end

  def time_to_english(time)
    # Convert a time (from database) to a string in English.
    # e.g. 9:00 => "9:00 AM"
    #      13:00 => "1:00 PM"
    time.strftime("%l:%M %p")
  end

  def course_section_time_to_english(course_section)
    # Returns a string like "Monday, Wednesday, Friday at 9:00 AM - 11:00 AM."
    days = days_bit_code_to_english(course_section.days_code)
    start_time = time_to_english(course_section.start_time.utc)
    end_time = time_to_english(course_section.end_time.utc)
    "#{days} at #{start_time} - #{end_time}"
  end

end
