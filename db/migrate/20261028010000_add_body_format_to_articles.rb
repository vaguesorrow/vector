class AddBodyFormatToArticles < ActiveRecord::Migration[8.1]
  def change
    add_column :articles, :body_format, :string, default: "markdown", null: false
  end
end
