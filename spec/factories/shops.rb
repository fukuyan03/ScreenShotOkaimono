FactoryBot.define do
  factory :shop do
    sequence(:name) { |n| "テストショップ#{n}" }
    association :user
  end
end
