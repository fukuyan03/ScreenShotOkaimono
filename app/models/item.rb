class Item < ApplicationRecord
  belongs_to :shop
  has_one_attached :image

  enum :status, { want: 0, interest: 1, purchased: 2, unnecessary: 3 }

  validates :name, presence: true
end
