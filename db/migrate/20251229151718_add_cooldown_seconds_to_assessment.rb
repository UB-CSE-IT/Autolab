class AddCooldownSecondsToAssessment < ActiveRecord::Migration[6.1]
  def change
    add_column :assessments, :submission_cooldown_seconds, :integer, null: false, default: 0
  end
end
