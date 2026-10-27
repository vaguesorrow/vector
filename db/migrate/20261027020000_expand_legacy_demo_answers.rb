class ExpandLegacyDemoAnswers < ActiveRecord::Migration[8.1]
  def up
    # Earlier seeds used two answers. Add only incorrect demo choices, preserving
    # answer IDs, correct choices and the results of existing attempts.
    questions = select_all(<<~SQL)
      SELECT quiz_questions.id FROM quiz_questions
      INNER JOIN quizzes ON quizzes.id = quiz_questions.quiz_id
      WHERE quizzes.title LIKE 'Демо:%'
    SQL
    questions.each do |question|
      id = connection.quote(question["id"])
      count = select_value("SELECT COUNT(*) FROM answer_options WHERE quiz_question_id = #{id}").to_i
      next if count >= 4

      position = select_value("SELECT MAX(position) FROM answer_options WHERE quiz_question_id = #{id}").to_i + 1
      (4 - count).times do
        body = connection.quote("Демонстрационный вариант #{position + 1}")
        execute <<~SQL
          INSERT INTO answer_options (quiz_question_id, body, position, correct, created_at, updated_at)
          VALUES (#{id}, #{body}, #{position}, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
        SQL
        position += 1
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Demo answers may already be in use"
  end
end
