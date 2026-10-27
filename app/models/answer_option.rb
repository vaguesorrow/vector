class AnswerOption < ApplicationRecord
  belongs_to :quiz_question, inverse_of: :answer_options
  has_many :quiz_answers, dependent: :restrict_with_error
  validates :body, :position, presence: true
  validates :position, uniqueness: { scope: :quiz_question_id }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  include ProtectQuizStructure
  validates :correct, inclusion: { in: [ true, false ] }
end
