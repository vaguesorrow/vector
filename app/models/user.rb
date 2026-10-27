class User < ApplicationRecord
  has_one :profile, dependent: :destroy
  has_many :articles, dependent: :restrict_with_error
  has_many :comments, dependent: :destroy
  has_many :article_likes, dependent: :destroy
  has_many :liked_articles, through: :article_likes, source: :article
  has_many :category_subscriptions, dependent: :destroy
  has_many :subscribed_categories, through: :category_subscriptions, source: :category
  has_many :quiz_attempts, dependent: :nullify
  validates :email, :role, presence: true
  validates :email, uniqueness: true
  enum :role, { "reader" => "reader", "editor" => "editor", "admin" => "admin" }, validate: true
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable
  accepts_nested_attributes_for :profile
  validates :profile, presence: true
  validates_associated :profile
  normalizes :email, with: ->(value) { value.strip.downcase }

  def display_name=(value)
    (profile || build_profile).display_name = value
  end

  def display_name
    profile&.display_name
  end
end
