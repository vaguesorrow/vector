# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_28_010000) do
  create_table "answer_options", force: :cascade do |t|
    t.bigint "quiz_question_id", null: false
    t.text "body", null: false
    t.integer "position", null: false
    t.boolean "correct", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["quiz_question_id", "position"], name: "index_answer_options_on_quiz_question_id_and_position", unique: true
    t.index ["quiz_question_id"], name: "index_answer_options_on_quiz_question_id"
  end

  create_table "article_likes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "article_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["article_id"], name: "index_article_likes_on_article_id"
    t.index ["user_id", "article_id"], name: "index_article_likes_on_user_id_and_article_id", unique: true
    t.index ["user_id"], name: "index_article_likes_on_user_id"
  end

  create_table "articles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "category_id", null: false
    t.string "title", null: false
    t.text "body", null: false
    t.text "excerpt"
    t.string "cover_url"
    t.boolean "published", default: false, null: false
    t.datetime "published_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "body_format", default: "markdown", null: false
    t.index ["category_id"], name: "index_articles_on_category_id"
    t.index ["user_id"], name: "index_articles_on_user_id"
    t.check_constraint "published = 0 OR published_at IS NOT NULL", name: "published_articles_have_date"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_categories_on_name", unique: true
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "category_subscriptions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_category_subscriptions_on_category_id"
    t.index ["user_id", "category_id"], name: "index_category_subscriptions_on_user_id_and_category_id", unique: true
    t.index ["user_id"], name: "index_category_subscriptions_on_user_id"
  end

  create_table "comments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "article_id", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["article_id"], name: "index_comments_on_article_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "newsletter_subscribers", force: :cascade do |t|
    t.string "email", null: false
    t.datetime "personal_data_consent_at"
    t.datetime "marketing_consent_at"
    t.datetime "unsubscribed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_newsletter_subscribers_on_email", unique: true
  end

  create_table "profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "display_name", null: false
    t.string "avatar_url"
    t.text "bio"
    t.string "audience_stage", default: "applicant", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_profiles_on_user_id", unique: true
    t.check_constraint "audience_stage IN ('school_student', 'applicant', 'first_year_student')", name: "profiles_audience_stage_values"
  end

  create_table "quiz_answers", force: :cascade do |t|
    t.bigint "quiz_attempt_id", null: false
    t.bigint "quiz_question_id", null: false
    t.bigint "answer_option_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["answer_option_id"], name: "index_quiz_answers_on_answer_option_id"
    t.index ["quiz_attempt_id", "quiz_question_id"], name: "index_quiz_answers_on_quiz_attempt_id_and_quiz_question_id", unique: true
    t.index ["quiz_attempt_id"], name: "index_quiz_answers_on_quiz_attempt_id"
    t.index ["quiz_question_id"], name: "index_quiz_answers_on_quiz_question_id"
  end

  create_table "quiz_attempts", force: :cascade do |t|
    t.bigint "quiz_id", null: false
    t.bigint "user_id"
    t.string "guest_token_digest"
    t.datetime "started_at", null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["guest_token_digest"], name: "index_quiz_attempts_on_guest_token_digest", unique: true, where: "guest_token_digest IS NOT NULL"
    t.index ["quiz_id"], name: "index_quiz_attempts_on_quiz_id"
    t.index ["user_id"], name: "index_quiz_attempts_on_user_id"
  end

  create_table "quiz_questions", force: :cascade do |t|
    t.bigint "quiz_id", null: false
    t.text "body", null: false
    t.integer "position", null: false
    t.text "explanation"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["quiz_id", "position"], name: "index_quiz_questions_on_quiz_id_and_position", unique: true
    t.index ["quiz_id"], name: "index_quiz_questions_on_quiz_id"
  end

  create_table "quizzes", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.string "cover_url"
    t.bigint "article_id"
    t.boolean "published", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["article_id"], name: "index_quizzes_on_article_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "role", default: "reader", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.check_constraint "role IN ('reader', 'editor', 'admin')", name: "users_role_values"
  end

  add_foreign_key "answer_options", "quiz_questions"
  add_foreign_key "article_likes", "articles"
  add_foreign_key "article_likes", "users"
  add_foreign_key "articles", "categories"
  add_foreign_key "articles", "users"
  add_foreign_key "category_subscriptions", "categories"
  add_foreign_key "category_subscriptions", "users"
  add_foreign_key "comments", "articles"
  add_foreign_key "comments", "users"
  add_foreign_key "profiles", "users"
  add_foreign_key "quiz_answers", "answer_options"
  add_foreign_key "quiz_answers", "quiz_attempts"
  add_foreign_key "quiz_answers", "quiz_questions"
  add_foreign_key "quiz_attempts", "quizzes"
  add_foreign_key "quiz_attempts", "users"
  add_foreign_key "quiz_questions", "quizzes"
  add_foreign_key "quizzes", "articles"
end
