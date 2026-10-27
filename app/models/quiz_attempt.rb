class QuizAttempt < ApplicationRecord
  belongs_to :quiz
  belongs_to :user, optional: true
  has_many :quiz_answers, dependent: :destroy
  validates :started_at, presence: true
  validates :guest_token_digest, uniqueness: true, allow_nil: true
  validate :preserve_attempt_owner_and_quiz, on: :update
  validate :completed_attempt_is_immutable, on: :update
  validate :all_questions_answered, if: -> { completed_at.present? }

  def score
    quiz_answers.joins(:answer_option).where(answer_options: { correct: true }).count
  end

  def total_questions
    quiz.quiz_questions.count
  end

  private

  def preserve_attempt_owner_and_quiz
    if quiz_id_changed? || user_id_changed? || guest_token_digest_changed?
      errors.add(:base, "Attempt owner and quiz cannot change")
    end
  end

  def completed_attempt_is_immutable
    errors.add(:base, "Completed attempt is immutable") if completed_at_in_database.present? && changed?
  end

  def all_questions_answered
    unless quiz_answers.pluck(:quiz_question_id).sort == quiz.quiz_questions.pluck(:id).sort
      errors.add(:completed_at, "requires answers to every question")
    end
  end
end
