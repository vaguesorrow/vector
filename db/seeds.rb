# Fictional demonstration content. Re-running seeds does not overwrite edited content.
ApplicationRecord.transaction do
  users = [ 1, 2 ].map do |number|
    User.find_or_create_by!(email: "demo#{number}@example.test") do |user|
      user.password = SecureRandom.base64(24)
      user.display_name = "Демо-пользователь #{number}"
    end
  end
  category = Category.find_or_create_by!(slug: "demo-documents") { |c| c.name = "Демо: документы" }
  article = Article.find_or_create_by!(user: users.first, title: "Демо: подготовка к поступлению") do |a|
    a.category = category
    a.body = "## Документы\n\nЭто демонстрационный материал."
    a.published = true
    a.published_at = Time.current
  end
  ArticleLike.find_or_create_by!(user: users.last, article: article)
  Comment.find_or_create_by!(user: users.last, article: article, body: "Демонстрационный комментарий")
  CategorySubscription.find_or_create_by!(user: users.last, category: category)
  quiz = Quiz.find_or_create_by!(title: "Демо: подготовка документов") do |q|
    q.article = article
    q.quiz_questions.build(body: "Демонстрационный вопрос", position: 0,
      answer_options_attributes: 4.times.map { |i| { body: "Вариант #{i + 1}", position: i, correct: i.zero? } })
    q.published = true
  end
  QuizProgress.start!(quiz: quiz, user: users.first) unless quiz.quiz_attempts.where(user: users.first).exists?
  QuizProgress.start!(quiz: quiz) unless quiz.quiz_attempts.where(user: nil).exists?
end
