class NewsletterSubscriber < ApplicationRecord
  validates :email, :personal_data_consent_at, presence: true
  validates :email, uniqueness: true
  normalizes :email, with: ->(value) { value.strip.downcase }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  scope :active, -> { where.not(marketing_consent_at: nil).where(unsubscribed_at: nil) }

  def self.subscribe!(email:, personal_data_consent:, marketing_consent: false)
    raise ArgumentError, "Personal data consent is required" unless personal_data_consent == true

    transaction do
      subscriber = find_or_initialize_by(email: email)
      subscriber.personal_data_consent_at = Time.current
      if marketing_consent == true
        subscriber.marketing_consent_at = Time.current
        subscriber.unsubscribed_at = nil
      end
      subscriber.save!
      subscriber
    end
  end
end
