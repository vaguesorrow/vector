class Profile < ApplicationRecord
  belongs_to :user
  validates :display_name, :audience_stage, presence: true
  enum :audience_stage, { "school_student" => "school_student", "applicant" => "applicant", "first_year_student" => "first_year_student" }, validate: true
  validates :user_id, uniqueness: true
end
