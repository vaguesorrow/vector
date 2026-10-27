class Quiz < ApplicationRecord
  belongs_to :article, optional: true
  has_many :quiz_attempts, dependent: :restrict_with_error
  has_many :quiz_questions, dependent: :destroy, inverse_of: :quiz
  accepts_nested_attributes_for :quiz_questions, allow_destroy: true
  validate :unique_question_positions
  validates :title, presence: true
  scope :publicly_visible, -> { where(published: true) }
  validates :published, inclusion: { in: [ true, false ] }
  validate :ready_for_publication, if: :published?

  private

  def unique_question_positions
    positions = quiz_questions.reject(&:marked_for_destruction?).map(&:position)
    errors.add(:quiz_questions, "Positions must be unique") if positions.uniq.size != positions.size
  end

  def ready_for_publication
    questions = quiz_questions.reject(&:marked_for_destruction?)
    errors.add(:quiz_questions, "must contain at least one question") if questions.empty?
    questions.each do |question|
      options = question.answer_options.reject(&:marked_for_destruction?)
      unless options.size == 4 && options.count(&:correct?) == 1
        errors.add(:quiz_questions, "must have exactly four options and exactly one correct answer")
      end
    end
  end
end
