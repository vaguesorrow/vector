require "digest"
require "securerandom"

class QuizProgress
  def self.start!(quiz:, user: nil)
    raise ArgumentError, "Quiz is not published" unless quiz.published?

    token = SecureRandom.urlsafe_base64(32) unless user
    attempt = quiz.quiz_attempts.create!(user: user, started_at: Time.current,
      guest_token_digest: token && Digest::SHA256.hexdigest(token))
    [ attempt, token ] # Store the raw token only in the protected Rails session.
  end

  def initialize(user: nil, guest_token: nil)
    @user = user
    @guest_token = guest_token
  end

  def find!(id)
    return @user.quiz_attempts.find(id) if @user
    raise ActiveRecord::RecordNotFound if @guest_token.blank?

    QuizAttempt.where(user_id: nil, guest_token_digest: Digest::SHA256.hexdigest(@guest_token)).find(id)
  end

  def answer!(attempt_id:, question_id:, answer_option_id:, complete: false)
    QuizAttempt.transaction do
      attempt = find!(attempt_id)
      attempt.with_lock do
        raise ArgumentError, "Completed attempt is immutable" if attempt.completed_at.present?

        question = attempt.quiz.quiz_questions.find(question_id)
        option = question.answer_options.find(answer_option_id)
        answer = attempt.quiz_answers.find_or_initialize_by(quiz_question: question)
        answer.update!(answer_option: option)
        attempt.update!(completed_at: Time.current) if complete
      end
      attempt
    end
  end
end
