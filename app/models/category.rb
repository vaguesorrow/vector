class Category < ApplicationRecord
  has_many :articles, dependent: :restrict_with_error
  has_many :category_subscriptions, dependent: :destroy
  has_many :subscribers, through: :category_subscriptions, source: :user
  validates :name, :slug, presence: true
  validates :name, uniqueness: true
  validates :slug, uniqueness: true
end
