class UbCourseSection < ApplicationRecord
  belongs_to :course

  def self.by_cud(course_user_datum, lecture_section = false)
    # Return a UbCourseSection for the given course_user_datum. Nil if none exists.
    # Set lecture_section to true to get the lecture section instead of the lab/rec section.

    section_name = lecture_section ? course_user_datum.lecture : course_user_datum.section
    if section_name.nil? || section_name.empty?
      return nil
    end

    course = course_user_datum.course

    UbCourseSection.where(course: course, name: section_name, is_lecture: lecture_section).first
  end

  def can_submit_at_time(time)
    current_day_name = time.strftime("%A") # e.g. "Monday"
    day_allowed = UbCourseSection.day_name_included_in_bit_code?(current_day_name, days_code)
    unless day_allowed
      return false
    end

    # Rails stores all times in UTC and then retrieves them as local times, but we're actually storing a local
    # time as if it were UTC. So we need to convert that "fake UTC" time into a real local time.
    # The time stored in the database is actually a local time so that daylight savings time is handled correctly.

    today = Date.today
    start_time_today = Time.new(today.year, today.month, today.day, start_time.utc.hour, start_time.utc.min, start_time.utc.sec)
    end_time_today = Time.new(today.year, today.month, today.day, end_time.utc.hour, end_time.utc.min, end_time.utc.sec)

    time >= start_time_today && time <= end_time_today
  end

  def to_h
    Time.use_zone("UTC") do
      {
        name: name,
        start_time: start_time.strftime("%T"),
        end_time: end_time.strftime("%T"),
        days_code: days_code,
        is_lecture: is_lecture
      }
    end
  end

  def time_to_english
    # Returns a string like "Monday, Wednesday, Friday at 9:00 AM - 11:00 AM."
    if start_time.nil? || end_time.nil?
      return "[No time set]"
    end

    days = UbCourseSection.days_bit_code_to_english(days_code)
    start_time_str = UbCourseSection.time_to_english_helper(start_time.utc)
    end_time_str = UbCourseSection.time_to_english_helper(end_time.utc)
    time_zone_name = Time.now.zone
    "#{days} at #{start_time_str} - #{end_time_str} (#{time_zone_name})"
  end

  def self.time_to_english_helper(time)
    # Convert a time (from database) to a string in English.
    # e.g. 9:00 => "9:00 AM"
    #      13:00 => "1:00 PM"
    #     13:30:15 => "1:30:15 PM"
    seconds = time.strftime("%S")
    seconds_str = seconds == "00" ? "" : ":#{seconds}"
    time.strftime("%l:%M#{seconds_str} %p")
  end

  def self.days_bit_code_to_english(bit_code)
    # Convert a bit code as it would be represented in the database to a string in English.
    # e.g. 2 => "Monday"
    #      6 => "Monday, Tuesday"
    #      127 => "Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, Saturday"
    day_names = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]
    day_names.select { |day_name| day_name_included_in_bit_code?(day_name, bit_code) }.join(", ")
  end

  def self.day_name_to_bit_code(day_name)
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

  def self.day_name_included_in_bit_code?(day_name, bit_code)
    # Check if a day name is included in a bit code as it would be represented in the database.
    day_name_to_bit_code(day_name) & bit_code != 0
  end

  def self.create_or_update(course_name, section_name, is_lecture, start_time_str, end_time_str, days_code)
    # Create or update a UbCourseSection. Returns the UbCourseSection.
    # UbCourseSection is uniquely identified by course_name, section_name, and is_lecture.
    # If course_name is not found, returns nil.
    # This is the only correct way to create or update a UbCourseSection, as it adjusts the time zone correctly.
    # Example call: UbCourseSection.create_or_update("local", "N1", false, "22:00:21", "23:00:00", 8)
    course = Course.find_by(name: course_name)
    if course.nil?
      return nil
    end

    section = UbCourseSection.where(course: course, name: section_name, is_lecture: is_lecture).first
    if section.nil?
      section = UbCourseSection.new
      section.course = course
      section.name = section_name
      section.is_lecture = is_lecture
    end

    Time.use_zone("UTC") do
      section.start_time = Time.zone.parse(start_time_str)
      section.end_time = Time.zone.parse(end_time_str)
    end

    section.days_code = days_code
    section.save!
  end

  def self.get_all_in_course(course_name)
    course = Course.find_by(name: course_name)
    if course.nil?
      return nil
    end

    UbCourseSection.where(course: course)
  end

end
