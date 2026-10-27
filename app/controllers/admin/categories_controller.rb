module Admin
  class CategoriesController < ResourcesController
    manages Category, "Категории", [
      [ :name, "Название", "text" ],
      [ :slug, "Slug", "text" ]
    ]
  end
end
