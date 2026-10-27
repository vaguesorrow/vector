module Admin
  class ArticlesController < ResourcesController
    manages Article, "Статьи", [
      [ :title, "Заголовок", "text" ],
      [ :user_id, "Автор", "User" ],
      [ :category_id, "Категория", "Category" ],
      [ :body, "Текст (Markdown)", "textarea" ],
      [ :excerpt, "Краткое описание", "textarea" ],
      [ :cover_url, "Обложка (URL)", "text" ],
      [ :published, "Опубликовано", "boolean" ],
      [ :published_at, "Дата публикации", "datetime" ]
    ]
  end
end
