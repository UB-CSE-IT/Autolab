class AddUbCourseSectionOptionsToAssessments < ActiveRecord::Migration[6.0]
  def change
    add_column :assessments, :use_ub_section_deadlines, :boolean, default: false
    add_column :assessments, :use_ub_lectures, :boolean, default: false
  end
end
