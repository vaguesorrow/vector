module ProtectQuizStructure
  extend ActiveSupport::Concern

  included do
    validate :protect_quiz_structure
    before_destroy :prevent_quiz_structure_deletion, prepend: true
  end

  private

  def structure_locked?
    quiz_ids = if is_a?(QuizQuestion)
      [ quiz_id, quiz_id_in_database ]
    else
      QuizQuestion.where(id: [ quiz_question_id, quiz_question_id_in_database ]).pluck(:quiz_id)
    end
    QuizAttempt.where(quiz_id: quiz_ids.compact).exists?
  end

  def protect_quiz_structure
    fields = is_a?(QuizQuestion) ? %w[quiz_id position] : %w[quiz_question_id position correct]
    if structure_locked? && (new_record? || (changes.keys & fields).any?)
      errors.add(:base, "Quiz structure is locked; create a new quiz revision")
    end
  end

  def prevent_quiz_structure_deletion
    if structure_locked?
      errors.add(:base, "Quiz structure is locked")
      throw :abort
    end
  end
end
