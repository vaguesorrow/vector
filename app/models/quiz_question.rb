class QuizQuestion < ApplicationRecord
  belongs_to :quiz, inverse_of: :quiz_questions
  has_many :answer_options, dependent: :destroy, inverse_of: :quiz_question
  accepts_nested_attributes_for :answer_options
  validate :four_options_and_one_correct
  has_many :quiz_answers, dependent: :restrict_with_error
  validates :body, :position, presence: true
  validates :position, uniqueness: { scope: :quiz_id }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  include ProtectQuizStructure
  private

  def four_options_and_one_correct
    options = answer_options.reject(&:marked_for_destruction?)
    unless options.size == 4 && options.count(&:correct?) == 1
      errors.add(:answer_options, "У вопроса должно быть ровно 4 варианта ответа и один правильный")
    end
    positions = options.map(&:position)
    errors.add(:answer_options, "Позиции ответов должны быть уникальными") if positions.uniq.size != positions.size
  end
end
