class AddAssessmentDependencies < ActiveRecord::Migration[6.1]
  def change
    add_reference :assessments, :depends_on_assessment, foreign_key: { to_table: :assessments }, null: true, type: :integer
    add_column :assessments, :dependency_minimum_score, :float, null: true
  end
end
