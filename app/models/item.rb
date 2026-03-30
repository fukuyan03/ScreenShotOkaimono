class Item < ApplicationRecord
  belongs_to :shop

  enum :status, { want: 0, interest: 1, purchased: 2, unnecessary: 3 }

  validates :name, presence: true
end
