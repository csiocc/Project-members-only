class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :post
  belongs_to :parent, class_name: "Comment", optional: true, inverse_of: :replies

  has_many :replies, -> { order(created_at: :asc) },
           class_name: "Comment", foreign_key: :parent_id, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :root_comments, -> { where(parent_id: nil).order(:created_at) }, class_name: "Comment"


  scope :roots, -> { where(parent_id: nil) }

  validates :body, presence: true

end
