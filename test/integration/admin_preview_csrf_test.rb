require "test_helper"

class AdminPreviewCsrfTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @previous_forgery_protection = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
  end

  teardown do
    ActionController::Base.allow_forgery_protection = @previous_forgery_protection
  end

  setup do
    @admin = User.create!(email: "csrf-admin@example.test", password: "password123", display_name: "Admin", role: "admin")
    @category = Category.create!(name: "Category", slug: "csrf-category")
    @article = Article.create!(title: "Original", body: "Body", user: @admin, category: @category)
    @quiz = Quiz.create!(title: "Original quiz")
    sign_in @admin
  end

  test "new article and quiz forms submit to preview with CSRF protection enabled" do
    [ [ new_admin_article_path, preview_admin_articles_path, :article ],
      [ new_admin_quiz_path, preview_admin_quizzes_path, :quiz ] ].each do |form_path, preview_path, key|
      get form_path
      token = form_token
      assert_no_difference [ "Article.count", "Quiz.count" ] do
        post preview_path, params: { authenticity_token: token, key => { title: "Draft preview" } }
      end
      assert_response :success
      assert_select ".admin-preview h2", "Draft preview"
    end
  end

  test "editing forms submit to preview and save with CSRF protection enabled" do
    [ [ edit_admin_article_path(@article), preview_admin_article_path(@article), admin_article_path(@article), :article, @article ],
      [ edit_admin_quiz_path(@quiz), preview_admin_quiz_path(@quiz), admin_quiz_path(@quiz), :quiz, @quiz ] ].each do |form_path, preview_path, save_path, key, record|
      get form_path
      token = form_token
      original = record.title
      patch preview_path, params: { authenticity_token: token, key => { title: "Unsaved preview" } }
      assert_response :success
      assert_select ".admin-preview h2", "Unsaved preview"
      assert_equal original, record.reload.title

      patch save_path, params: { authenticity_token: token, key => { title: "Saved title" } }
      assert_response :redirect
      assert_equal "Saved title", record.reload.title
    end
  end

  test "preview rejects missing or invalid CSRF tokens" do
    get edit_admin_article_path(@article)
    [ nil, "invalid-token" ].each do |token|
      patch preview_admin_article_path(@article), params: { authenticity_token: token, article: { title: "Rejected" } }
      assert_response :unprocessable_content
      assert_equal "Original", @article.reload.title
    end
  end

  private

  def form_token
    assert_response :success
    token = css_select("form.admin-editor input[name=authenticity_token]").first&.[]("value")
    assert token.present?
    token
  end
end
