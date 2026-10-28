require "test_helper"

class AdminPreviewsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = User.create!(email: "preview-admin@example.test", password: "password123", display_name: "Автор", role: "admin")
    @category = Category.create!(name: "Категория", slug: "preview-category")
    @article = Article.create!(title: "Статья", body: "## Заголовок", user: @admin, category: @category)
    @quiz = Quiz.create!(title: "Тест")
    @question = @quiz.quiz_questions.create!(body: "Вопрос", position: 0, explanation: "Объяснение",
      answer_options_attributes: 4.times.map { |i| { body: "Ответ #{i}", position: i, correct: i.zero? } })
  end

  test "previews require administrator access" do
    get preview_admin_article_path(@article)
    assert_redirected_to new_user_session_path
    post preview_admin_quizzes_path, params: { quiz: { title: "Draft" } }
    assert_redirected_to new_user_session_path
    %w[reader editor].each do |role|
      sign_in User.create!(email: "preview-#{role}@example.test", password: "password123", display_name: role, role: role)
      get preview_admin_article_path(@article)
      assert_response :forbidden
      post preview_admin_quiz_path(@quiz), params: { quiz: { title: "Draft" } }
      assert_response :forbidden
    end
  end

  test "article preview shows unsaved changes without changing the record" do
    sign_in @admin
    get preview_admin_article_path(@article)
    assert_response :success
    assert_select ".admin-preview h2", "Статья"

    assert_no_difference "Article.count" do
      patch preview_admin_article_path(@article), params: { article: { title: "Несохранённый заголовок", body_format: "html",
        body: '<p><span class="ql-font-fyl" style="font-size:28px">Текст</span></p>', cover_url: "javascript:alert(1)" } }
    end
    assert_response :success
    assert_select ".admin-preview h2", "Несохранённый заголовок"
    assert_select "textarea[data-article-preview-target=source]", text: /ql-font-fyl/
    assert_select ".admin-preview__cover", count: 0
    assert_equal "Статья", @article.reload.title
    assert_equal "markdown", @article.body_format
  end

  test "new article and quiz drafts can be previewed before validation" do
    sign_in @admin
    assert_no_difference [ "Article.count", "Quiz.count" ] do
      post preview_admin_articles_path, params: { article: { title: "Новая статья" } }
      assert_response :success
      post preview_admin_quizzes_path, params: { quiz: { title: "Новый тест" } }
      assert_response :success
      assert_select ".admin-preview h2", "Новый тест"
      assert_select ".admin-preview", text: /В тесте пока нет вопросов/
    end
  end

  test "quiz preview shows unsaved nested questions and excludes removed ones without saving" do
    sign_in @admin
    assert_no_difference [ "Quiz.count", "QuizQuestion.count", "AnswerOption.count", "QuizAttempt.count" ] do
      patch preview_admin_quiz_path(@quiz), params: { quiz: { title: "Черновик теста", quiz_questions_attributes: {
        "0" => { id: @question.id, _destroy: "1" },
        "1" => { body: "Новый вопрос", position: 1, explanation: "Новое объяснение",
          answer_options_attributes: 4.times.to_h { |i| [ i.to_s, { body: "Новый ответ #{i}", position: i, correct: i == 2 } ] } }
      } } }
    end
    assert_response :success
    assert_select "fieldset", count: 1
    assert_select "legend", "1. Новый вопрос"
    assert_select "input[type=radio]", count: 4
    assert_select "input[data-correct=true]", count: 1
    assert_select ".admin-preview__feedback", text: /Новое объяснение/
    assert_equal "Тест", @quiz.reload.title
    assert_equal "Вопрос", @question.reload.body
    assert_equal 1, @quiz.quiz_questions.count
  end

  test "forms and lists link to previews" do
    sign_in @admin
    [ [ @article, admin_articles_path, new_admin_article_path ], [ @quiz, admin_quizzes_path, new_admin_quiz_path ] ].each do |record, list, form|
      get list
      assert_select "a[href=?][target=_blank]", admin_preview_path_for(record), text: "Превью"
      get form
      assert_select "button[formtarget=_blank][formnovalidate]", "Превью"
    end
  end

  private

  def admin_preview_path_for(record)
    record.is_a?(Article) ? preview_admin_article_path(record) : preview_admin_quiz_path(record)
  end
end
