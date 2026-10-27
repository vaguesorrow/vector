class Article < ApplicationRecord
  belongs_to :user
  belongs_to :category
  has_many :comments, dependent: :destroy
  has_many :article_likes, dependent: :destroy
  has_many :liking_users, through: :article_likes, source: :user
  validates :title, :body, presence: true
  has_many :quizzes, dependent: :nullify
  validates :published, inclusion: { in: [ true, false ] }
  validates :published_at, presence: true, if: :published?
  scope :publicly_visible, -> { where(published: true).where("published_at <= ?", Time.current) }
end
