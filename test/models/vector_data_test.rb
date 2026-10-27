require "test_helper"

class VectorDataTest < ActiveSupport::TestCase
  setup do
    @one = User.create!(email: "one@example.test", password: "password123", display_name: "One")
    @two = User.create!(email: "two@example.test", password: "password123", display_name: "Two")
    @category = Category.create!(name: "Documents", slug: "documents")
    @article = @one.articles.create!(category: @category, title: "Demo article", body: "## Heading")
  end

  test "profile and personal links are unique and required values reject blank strings" do
    assert_not User.new(email: "missing@example.test", password: "password123").valid?
    assert_not Profile.new(user: @one, display_name: "Duplicate").valid?
    assert_not @one.profile.update(display_name: " ")
    @one.article_likes.create!(article: @article)
    assert_not @one.article_likes.new(article: @article).valid?
    @one.category_subscriptions.create!(category: @category)
    assert_not @one.category_subscriptions.new(category: @category).valid?
    assert_raises(ActiveRecord::RecordNotUnique) do
      ArticleLike.insert_all!([ { user_id: @one.id, article_id: @article.id } ])
    end
  end

  test "public articles require publication date and exclude future or draft content" do
    assert_not Article.publicly_visible.exists?(@article.id)
    assert_not @article.update(published: true)
    @article.update!(published: true, published_at: 1.day.from_now)
    assert_not Article.publicly_visible.exists?(@article.id)
    @article.update!(published_at: 1.day.ago)
    assert Article.publicly_visible.exists?(@article.id)
  end

  test "questions require exactly four options and one correct answer" do
    quiz = Quiz.create!(title: "Draft")
    assert_not quiz.update(published: true)
    question = quiz.quiz_questions.build(body: "Question", position: 0)
    question.answer_options.build(body: "One", position: 0, correct: true)
    assert_not question.valid?
    3.times { |i| question.answer_options.build(body: "Other", position: i + 1, correct: false) }
    assert question.valid?
    question.answer_options.last.correct = true
    assert_not question.valid?
    question.answer_options.last.correct = false
    quiz.update!(published: true)
  end

  test "quiz answers are consistent and completion is transactional and immutable" do
    quiz = build_quiz
    attempt, = QuizProgress.start!(quiz: quiz, user: @one)
    service = QuizProgress.new(user: @one)
    first, second = quiz.quiz_questions.order(:position).to_a
    assert_not attempt.quiz_answers.new(quiz_question: first, answer_option: second.answer_options.first).valid?
    foreign = build_quiz
    assert_not attempt.quiz_answers.new(quiz_question: foreign.quiz_questions.first,
      answer_option: foreign.quiz_questions.first.answer_options.first).valid?
    assert_raises(ActiveRecord::RecordInvalid) do
      service.answer!(attempt_id: attempt.id, question_id: first.id,
        answer_option_id: first.answer_options.first.id, complete: true)
    end
    assert_equal 0, attempt.quiz_answers.count
    service.answer!(attempt_id: attempt.id, question_id: first.id, answer_option_id: first.answer_options.last.id)
    service.answer!(attempt_id: attempt.id, question_id: first.id, answer_option_id: first.answer_options.first.id)
    assert_equal 1, attempt.quiz_answers.count
    service.answer!(attempt_id: attempt.id, question_id: second.id,
      answer_option_id: second.answer_options.first.id, complete: true)
    assert_equal 2, attempt.reload.score
    assert_equal 2, attempt.total_questions
    assert_not attempt.quiz_answers.first.update(answer_option: first.answer_options.last)
    assert_not attempt.quiz_answers.first.destroy
    assert_not attempt.update(completed_at: nil)
    assert_not first.update(position: 10)
    assert_not first.answer_options.first.update(correct: false)
    assert_not first.answer_options.first.destroy
    assert_not first.destroy
    assert first.reload.update(body: "Typo corrected")
    assert_not_equal attempt, QuizProgress.start!(quiz: quiz, user: @one).first
  end

  test "guest access needs token and user deletion anonymizes attempts" do
    quiz = build_quiz
    attempt, token = QuizProgress.start!(quiz: quiz)
    assert_not_equal token, attempt.guest_token_digest
    assert_equal attempt, QuizProgress.new(guest_token: token).find!(attempt.id)
    [ QuizProgress.new, QuizProgress.new(guest_token: "wrong"), QuizProgress.new(user: @two) ].each do |service|
      assert_raises(ActiveRecord::RecordNotFound) { service.find!(attempt.id) }
    end
    personal, = QuizProgress.start!(quiz: quiz, user: @two)
    @two.destroy!
    assert_nil personal.reload.user_id
    assert_nil personal.guest_token_digest
    assert_raises(ActiveRecord::RecordNotFound) { QuizProgress.new(guest_token: token).find!(personal.id) }
  end

  test "newsletter normalization explicit consent and resubscription" do
    assert_raises(ArgumentError) { NewsletterSubscriber.subscribe!(email: "demo@example.test", personal_data_consent: false) }
    subscriber = NewsletterSubscriber.subscribe!(email: " DEMO@example.test ", personal_data_consent: true)
    assert_equal "demo@example.test", subscriber.email
    assert_nil subscriber.marketing_consent_at
    subscriber.update!(unsubscribed_at: Time.current)
    NewsletterSubscriber.subscribe!(email: "demo@example.test", personal_data_consent: true)
    assert subscriber.reload.unsubscribed_at
    assert_equal 0, NewsletterSubscriber.active.count
    NewsletterSubscriber.subscribe!(email: "demo@example.test", personal_data_consent: true, marketing_consent: true)
    assert_nil subscriber.reload.unsubscribed_at
    assert_equal 1, NewsletterSubscriber.active.count
  end

  test "seed data can be loaded twice without duplicates" do
    load Rails.root.join("db/seeds.rb")
    counts = ApplicationRecord.descendants.reject(&:abstract_class?).to_h { |model| [ model.name, model.count ] }
    load Rails.root.join("db/seeds.rb")
    counts.each { |name, count| assert_equal count, name.constantize.count, name }
  end

  private

  def build_quiz
    quiz = Quiz.create!(title: "Demo quiz")
    2.times do |index|
      quiz.quiz_questions.create!(body: "Question #{index}", position: index,
        answer_options_attributes: 4.times.map { |i| { body: "Answer #{i}", position: i, correct: i.zero? } })
    end
    quiz.update!(published: true)
    quiz
  end
end
