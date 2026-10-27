class AddConsentTimestampsToSubscribers < ActiveRecord::Migration[8.1]
  def change
    add_column :subscribers, :personal_data_consent_at, :datetime
    add_column :subscribers, :marketing_consent_at, :datetime
  end
end
