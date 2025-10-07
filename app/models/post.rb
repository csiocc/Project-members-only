class Post < ApplicationRecord
  validates :title, presence: true
  validates :body, presence: true
  belongs_to :user
  has_many :comments, dependent: :destroy
  has_many :root_comments, -> { where(parent_id: nil).order(created_at: :asc) },
           class_name: "Comment"
end
