class QuizAnswer < ApplicationRecord
  belongs_to :quiz_attempt
  belongs_to :quiz_question
  belongs_to :answer_option
  validates :quiz_question_id, uniqueness: { scope: :quiz_attempt_id }
  validate :consistent_answer
  before_destroy :protect_completed_answer

  private

  def consistent_answer
    attempts = [ quiz_attempt, QuizAttempt.find_by(id: quiz_attempt_id_in_database) ].compact
    errors.add(:base, "Completed attempt is immutable") if attempts.any? { |attempt| attempt.completed_at.present? }
    if quiz_question && quiz_attempt && quiz_question.quiz_id != quiz_attempt.quiz_id
      errors.add(:quiz_question, "must belong to the attempt quiz")
    end
    if answer_option && answer_option.quiz_question_id != quiz_question_id
      errors.add(:answer_option, "must belong to the question")
    end
  end

  def protect_completed_answer
    if quiz_attempt.completed_at.present? && !destroyed_by_association
      errors.add(:base, "Completed attempt is immutable")
      throw :abort
    end
  end
end
