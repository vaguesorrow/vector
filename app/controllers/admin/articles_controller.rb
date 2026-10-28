module Admin
  class ArticlesController < ResourcesController
    manages Article, "Статьи", [
      [ :title, "Заголовок", "text" ],
      [ :user_id, "Автор", "User" ],
      [ :category_id, "Категория", "Category" ],
      [ :body, "Текст статьи", "rich_text" ],
      [ :excerpt, "Краткое описание", "textarea" ],
      [ :cover_url, "Обложка (URL)", "text" ],
      [ :published, "Опубликовано", "boolean" ],
      [ :published_at, "Дата публикации", "datetime" ]
    ]

    private

    def record_params
      super.merge(params.require(:article).permit(:body_format))
    end
  end
end
