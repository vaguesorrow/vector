class CreateVectorData < ActiveRecord::Migration[8.1]
  def change
    create_table :users, id: :bigint do |t|
      t.string :email, null: false
      t.string :encrypted_password, null: false, default: ""
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
      t.string :role, null: false, default: "reader"
      t.timestamps null: false
    end
    add_index :users, :reset_password_token, unique: true
    add_index :users, %i[email], unique: true
    add_check_constraint :users, "role IN ('reader', 'editor', 'admin')", name: "users_role_values"
    create_table :profiles, id: :bigint do |t|
      t.references :user, foreign_key: true, type: :bigint, index: { unique: true }, null: false
      t.string :display_name, null: false
      t.string :avatar_url
      t.text :bio
      t.string :audience_stage, null: false, default: "applicant"
      t.timestamps null: false
    end
    add_check_constraint :profiles, "audience_stage IN ('school_student', 'applicant', 'first_year_student')", name: "profiles_audience_stage_values"
    create_table :categories, id: :bigint do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.timestamps null: false
    end
    add_index :categories, %i[name], unique: true
    add_index :categories, %i[slug], unique: true
    create_table :tags, id: :bigint do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.timestamps null: false
    end
    add_index :tags, %i[name], unique: true
    add_index :tags, %i[slug], unique: true
    create_table :articles, id: :bigint do |t|
      t.references :user, foreign_key: true, type: :bigint, null: false
      t.references :category, foreign_key: true, type: :bigint, null: false
      t.string :title, null: false
      t.text :body, null: false
      t.text :excerpt
      t.string :cover_url
      t.boolean :published, null: false, default: false
      t.datetime :published_at
      t.timestamps null: false
    end
    add_check_constraint :articles, "published = 0 OR published_at IS NOT NULL", name: "published_articles_have_date"
    create_table :article_tags, id: :bigint do |t|
      t.references :article, foreign_key: true, type: :bigint, null: false
      t.references :tag, foreign_key: true, type: :bigint, null: false
      t.timestamps null: false
    end
    add_index :article_tags, %i[article_id tag_id], unique: true
    create_table :comments, id: :bigint do |t|
      t.references :user, foreign_key: true, type: :bigint, null: false
      t.references :article, foreign_key: true, type: :bigint, null: false
      t.text :body, null: false
      t.timestamps null: false
    end
    create_table :article_likes, id: :bigint do |t|
      t.references :user, foreign_key: true, type: :bigint, null: false
      t.references :article, foreign_key: true, type: :bigint, null: false
      t.timestamps null: false
    end
    add_index :article_likes, %i[user_id article_id], unique: true
    create_table :category_subscriptions, id: :bigint do |t|
      t.references :user, foreign_key: true, type: :bigint, null: false
      t.references :category, foreign_key: true, type: :bigint, null: false
      t.timestamps null: false
    end
    add_index :category_subscriptions, %i[user_id category_id], unique: true
    create_table :universities, id: :bigint do |t|
      t.string :name, null: false
      t.string :short_name
      t.string :city, null: false
      t.text :description
      t.string :website_url
      t.string :cover_url
      t.timestamps null: false
    end
    create_table :faculties, id: :bigint do |t|
      t.references :university, foreign_key: true, type: :bigint, null: false
      t.string :name, null: false
      t.timestamps null: false
    end
    add_index :faculties, %i[university_id name], unique: true
    create_table :educational_programs, id: :bigint do |t|
      t.references :faculty, foreign_key: true, type: :bigint, null: false
      t.string :name, null: false
      t.text :description
      t.string :website_url
      t.timestamps null: false
    end
    add_index :educational_programs, %i[faculty_id name], unique: true
    create_table :admission_methods, id: :bigint do |t|
      t.string :name, null: false
      t.text :description
      t.timestamps null: false
    end
    add_index :admission_methods, %i[name], unique: true
    create_table :admission_options, id: :bigint do |t|
      t.references :educational_program, foreign_key: true, type: :bigint, null: false
      t.references :admission_method, foreign_key: true, type: :bigint, null: false
      t.integer :admission_year, null: false
      t.string :source_url
      t.datetime :verified_at
      t.timestamps null: false
    end
    add_index :admission_options, %i[educational_program_id admission_method_id admission_year], unique: true
    create_table :deadlines, id: :bigint do |t|
      t.references :admission_option, foreign_key: true, type: :bigint, null: false
      t.string :title, null: false
      t.text :description
      t.date :due_on, null: false
      t.integer :position, null: false, default: 0
      t.string :source_url
      t.datetime :verified_at
      t.timestamps null: false
    end
    create_table :admission_routes, id: :bigint do |t|
      t.references :user, foreign_key: true, type: :bigint, null: false
      t.references :admission_option, foreign_key: true, type: :bigint, null: false
      t.timestamps null: false
    end
    add_index :admission_routes, %i[user_id admission_option_id], unique: true
    create_table :route_tasks, id: :bigint do |t|
      t.references :admission_route, foreign_key: true, type: :bigint, null: false
      t.references :deadline, foreign_key: true, type: :bigint, null: false
      t.datetime :completed_at
      t.timestamps null: false
    end
    add_index :route_tasks, %i[admission_route_id deadline_id], unique: true
    create_table :quizzes, id: :bigint do |t|
      t.string :title, null: false
      t.text :description
      t.string :cover_url
      t.references :article, foreign_key: true, type: :bigint
      t.boolean :published, null: false, default: false
      t.timestamps null: false
    end
    create_table :quiz_questions, id: :bigint do |t|
      t.references :quiz, foreign_key: true, type: :bigint, null: false
      t.text :body, null: false
      t.integer :position, null: false
      t.text :explanation
      t.timestamps null: false
    end
    add_index :quiz_questions, %i[quiz_id position], unique: true
    create_table :answer_options, id: :bigint do |t|
      t.references :quiz_question, foreign_key: true, type: :bigint, null: false
      t.text :body, null: false
      t.integer :position, null: false
      t.boolean :correct, null: false, default: false
      t.timestamps null: false
    end
    add_index :answer_options, %i[quiz_question_id position], unique: true
    create_table :quiz_attempts, id: :bigint do |t|
      t.references :quiz, foreign_key: true, type: :bigint, null: false
      t.references :user, foreign_key: true, type: :bigint
      t.string :guest_token_digest
      t.datetime :started_at, null: false
      t.datetime :completed_at
      t.timestamps null: false
    end
    add_index :quiz_attempts, :guest_token_digest, unique: true, where: "guest_token_digest IS NOT NULL"
    create_table :quiz_answers, id: :bigint do |t|
      t.references :quiz_attempt, foreign_key: true, type: :bigint, null: false
      t.references :quiz_question, foreign_key: true, type: :bigint, null: false
      t.references :answer_option, foreign_key: true, type: :bigint, null: false
      t.timestamps null: false
    end
    add_index :quiz_answers, %i[quiz_attempt_id quiz_question_id], unique: true
    create_table :newsletter_subscribers, id: :bigint do |t|
      t.string :email, null: false
      t.datetime :personal_data_consent_at, null: false
      t.datetime :marketing_consent_at
      t.datetime :unsubscribed_at
      t.timestamps null: false
    end
    add_index :newsletter_subscribers, %i[email], unique: true
  end
end
