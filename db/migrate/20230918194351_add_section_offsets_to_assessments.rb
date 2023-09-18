class AddSectionOffsetsToAssessments < ActiveRecord::Migration[6.0]
  def change
    add_column :assessments, :ub_section_start_offset, :integer, default: 0
    add_column :assessments, :ub_section_end_offset, :integer, default: 0
  end
end
