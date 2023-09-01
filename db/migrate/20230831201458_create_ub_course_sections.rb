class CreateUbCourseSections < ActiveRecord::Migration[6.0]
  def change
    create_table :ub_course_sections do |t|
      t.integer :course_id
      t.string :name # "A" for lecture or "A1" for section. Must match what's in the roster
      t.boolean :is_lecture # true if this is a lecture, false if this is a (lab/rec) section
      t.time :start_time
      t.time :end_time
      t.integer :days_code # 0b0000001 for Sunday, 0b0000010 for Monday, 0b0000011 for Sunday and Monday, etc.

      t.timestamps
    end
  end
end
