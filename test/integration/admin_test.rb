require "test_helper"

class AdminTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = User.create!(email: "admin@example.test", password: "password123", display_name: "Admin", role: "admin")
    @category = Category.create!(name: "Documents", slug: "documents")
  end

  test "admin pages and mutations require admin role" do
    get admin_root_path
    assert_redirected_to new_user_session_path
    %w[reader editor].each do |role|
      user = User.create!(email: "#{role}@example.test", password: "password123", display_name: role, role: role)
      sign_in user
      get admin_root_path
      assert_response :forbidden
      %w[articles categories quizzes].each do |resource|
        get "/admin/#{resource}"
        assert_response :forbidden
        post "/admin/#{resource}", params: {}
        assert_response :forbidden
        delete "/admin/#{resource}/1"
        assert_response :forbidden
      end
      patch admin_quiz_path(1), params: {}
      assert_response :forbidden
      sign_out user
    end
  end

  test "admin can open content lists and forms" do
    sign_in @admin
    %w[articles categories quizzes].each do |resource|
      get "/admin/#{resource}"
      assert_response :success
      get "/admin/#{resource}/new"
      assert_response :success
    end
    get new_admin_quiz_path
    assert_select "fieldset[data-question]", minimum: 1
    assert_select 'input[name*="answer_options_attributes"][name$="[body]"]', minimum: 4
  end

  test "article CRUD and category deletion protection" do
    sign_in @admin
    post admin_articles_path, params: { article: { title: "Article", body: "Body", category_id: @category.id, user_id: @admin.id } }
    article = Article.last
    assert_redirected_to edit_admin_article_path(article)
    patch admin_article_path(article), params: { article: { title: "Updated" } }
    assert_equal "Updated", article.reload.title
    delete admin_category_path(@category)
    assert_redirected_to admin_categories_path
    follow_redirect!
    assert_select "[role=alert]"
    assert Category.exists?(@category.id)
    delete admin_article_path(article)
    assert_not Article.exists?(article.id)
    delete admin_category_path(@category)
    assert_not Category.exists?(@category.id)
    post admin_categories_path, params: { category: { name: "New", slug: "new" } }
    assert_redirected_to admin_categories_path
    assert Category.exists?(slug: "new")
  end

  test "quiz nested creation editing adding questions removing questions and deletion" do
    sign_in @admin
    post admin_quizzes_path, params: { quiz: quiz_params }
    quiz = Quiz.last
    assert_redirected_to edit_admin_quiz_path(quiz)
    assert_equal 1, quiz.quiz_questions.count
    question = quiz.quiz_questions.sole
    assert_equal 4, question.answer_options.count
    assert_equal 1, question.answer_options.where(correct: true).count
    get edit_admin_quiz_path(quiz)
    assert_response :success
    patch admin_quiz_path(quiz), params: { quiz: { title: "Updated", quiz_questions_attributes: {
      "0" => { id: question.id, body: "Edited", answer_options_attributes: question.answer_options.order(:position).each_with_index.to_h { |option, i| [ i.to_s, { id: option.id, body: "Edited #{i}", correct: i == 2 } ] } },
      "1" => question_params(1)
    } } }
    assert_response :see_other
    assert_equal "Edited", question.reload.body
    assert_equal 2, quiz.quiz_questions.count
    assert_equal 2, question.answer_options.find_by!(correct: true).position
    added = quiz.quiz_questions.order(:position).last
    patch admin_quiz_path(quiz), params: { quiz: { quiz_questions_attributes: { "0" => { id: added.id, _destroy: "1" } } } }
    assert_response :see_other
    assert_not QuizQuestion.exists?(added.id)
    delete admin_quiz_path(quiz)
    assert_not Quiz.exists?(quiz.id)
    assert_not QuizQuestion.exists?(question.id)
    assert_equal 0, AnswerOption.count
  end

  test "invalid question options roll back entire quiz" do
    sign_in @admin
    [ 3, 5 ].each do |count|
      attributes = quiz_params
      attributes[:quiz_questions_attributes]["0"][:answer_options_attributes] = count.times.to_h { |i| [ i.to_s, { body: "Answer", position: i, correct: i.zero? } ] }
      assert_no_difference [ "Quiz.count", "QuizQuestion.count", "AnswerOption.count" ] do
        post admin_quizzes_path, params: { quiz: attributes }
      end
      assert_response :unprocessable_content
    end
    attributes = quiz_params
    attributes[:quiz_questions_attributes]["0"][:answer_options_attributes]["1"][:correct] = true
    post admin_quizzes_path, params: { quiz: attributes }
    assert_response :unprocessable_content
    assert_equal 0, Quiz.count
  end

  test "attempts protect structure answers and quiz deletion" do
    sign_in @admin
    post admin_quizzes_path, params: { quiz: quiz_params }
    quiz = Quiz.last
    QuizProgress.start!(quiz: quiz, user: @admin)
    question = quiz.quiz_questions.sole
    option = question.answer_options.first
    patch admin_quiz_path(quiz), params: { quiz: { quiz_questions_attributes: { "0" => { id: question.id,
      answer_options_attributes: { "0" => { id: option.id, correct: false } } } } } }
    assert_response :unprocessable_content
    assert option.reload.correct?
    delete admin_quiz_path(quiz)
    assert Quiz.exists?(quiz.id)
    assert QuizQuestion.exists?(question.id)
  end

  private

  def question_params(position)
    { body: "Question #{position}", position: position, answer_options_attributes:
      4.times.to_h { |i| [ i.to_s, { body: "Answer #{i}", position: i, correct: i.zero? } ] } }
  end

  def quiz_params
    { title: "Quiz", published: "1", quiz_questions_attributes: { "0" => question_params(0) } }
  end
end
