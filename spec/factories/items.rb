FactoryBot.define do
  factory :item do
    name { "スリッパ" }
    brand { "無印良品" }
    price { 1990 }
    summary { "シンプルな室内用スリッパ" }
    source_platform { "Instagram" }
    source_author_name { "muji" }
    status { :interest }
    association :shop
  end
end
