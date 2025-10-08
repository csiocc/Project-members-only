class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :post, inverse_of: :comments
  belongs_to :parent, class_name: "Comment", optional: true, inverse_of: :replies

  has_many :replies, -> { order(created_at: :asc) },
           class_name: "Comment", 
           foreign_key: :parent_id, 
           dependent: :destroy,
           inverse_of: :parent

  scope :roots, -> { where(parent_id: nil) }

  validates :body, presence: true

end
