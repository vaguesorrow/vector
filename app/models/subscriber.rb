class Subscriber < ApplicationRecord
  normalizes :email, with: ->(email) { email.strip.downcase }
  validates :email, presence: true, uniqueness: { case_sensitive: false },
    format: { with: URI::MailTo::EMAIL_REGEXP }
end
