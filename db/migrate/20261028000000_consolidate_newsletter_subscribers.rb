class ConsolidateNewsletterSubscribers < ActiveRecord::Migration[8.1]
  def up
    # Legacy rows may have no recorded consent. Preserve that absence rather
    # than assigning consent retrospectively.
    change_column_null :newsletter_subscribers, :personal_data_consent_at, true

    execute <<~SQL
      INSERT INTO newsletter_subscribers
        (email, personal_data_consent_at, marketing_consent_at, created_at, updated_at)
      SELECT lower(trim(email)), personal_data_consent_at, marketing_consent_at, created_at, updated_at
      FROM subscribers WHERE true
      ON CONFLICT(email) DO UPDATE SET
        personal_data_consent_at = COALESCE(newsletter_subscribers.personal_data_consent_at, excluded.personal_data_consent_at),
        marketing_consent_at = COALESCE(newsletter_subscribers.marketing_consent_at, excluded.marketing_consent_at),
        created_at = MIN(newsletter_subscribers.created_at, excluded.created_at),
        updated_at = MAX(newsletter_subscribers.updated_at, excluded.updated_at)
    SQL

    drop_table :subscribers
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Subscriber records have been merged into newsletter_subscribers"
  end
end
