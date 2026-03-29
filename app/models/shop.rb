class Shop < ApplicationRecord
  belongs_to :user

  validates :name, presence: true, length: { maximum: 255 }
  validates :name, uniqueness: { scope: :user_id, case_sensitive: false }
end
