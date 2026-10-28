class Article < ApplicationRecord
  belongs_to :user
  belongs_to :category
  has_many :comments, dependent: :destroy
  has_many :article_likes, dependent: :destroy
  has_many :liking_users, through: :article_likes, source: :user
  validates :title, :body, presence: true
  validates :body_format, inclusion: { in: %w[markdown html] }
  before_validation :sanitize_formatted_body
  has_many :quizzes, dependent: :nullify
  validates :published, inclusion: { in: [ true, false ] }
  validates :published_at, presence: true, if: :published?
  scope :publicly_visible, -> { where(published: true).where("published_at <= ?", Time.current) }

  private

  def sanitize_formatted_body
    return unless body_format == "html" && (will_save_change_to_body? || will_save_change_to_body_format?)

    self.body = Rails::HTML5::SafeListSanitizer.new.sanitize(body.to_s,
      tags: %w[p br h1 h2 h3 strong b em i u s blockquote pre code ol ul li a span sub sup],
      attributes: %w[href title class style])
    self.body = "" if Rails::HTML5::SafeListSanitizer.new.sanitize(body, tags: [], attributes: [])
      .gsub(/\u00a0|\u200b/, " ").strip.empty?
  end
end
