module Admin
  class QuizzesController < ResourcesController
    manages Quiz, "Тесты", [
      [ :title, "Название", "text" ],
      [ :description, "Описание", "textarea" ],
      [ :cover_url, "Обложка (URL)", "text" ],
      [ :article_id, "Статья (необязательно)", "Article" ],
      [ :published, "Опубликовано", "boolean" ]
    ]
    before_action :prepare_questions, only: %i[new edit]

    private

    def prepare_questions
      # ResourcesController initializes a new record in its new action.
      @record ||= Quiz.new
      @record.quiz_questions.build(position: 0) if @record.quiz_questions.empty?
      @record.quiz_questions.each do |question|
        used = question.answer_options.map(&:position)
        (0...4).each do |position|
          question.answer_options.build(position: position, correct: position.zero?) unless used.include?(position)
        end
      end
    end

    def record_params
      params.require(:quiz).permit(:title, :description, :cover_url, :article_id, :published,
        quiz_questions_attributes: [ :id, :body, :position, :explanation, :_destroy,
          answer_options_attributes: [ :id, :body, :position, :correct ] ])
    end
  end
end
