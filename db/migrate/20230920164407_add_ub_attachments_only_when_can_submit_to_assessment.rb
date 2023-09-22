class AddUbAttachmentsOnlyWhenCanSubmitToAssessment < ActiveRecord::Migration[6.0]
  def change
    add_column :assessments, :ub_attachments_only_when_can_submit, :boolean, default: false
  end
end
