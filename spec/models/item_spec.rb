require "rails_helper"

RSpec.describe Item, type: :model do
  it "name がないと無効" do
    item = build(:item, name: nil)

    expect(item).not_to be_valid
    expect(item.errors[:name]).to be_present
  end

  it "status enum が使える" do
    item = build(:item, status: :want)

    expect(item).to be_want

    item.status = :purchased

    expect(item).to be_purchased
  end
end
