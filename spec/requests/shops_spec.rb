require "rails_helper"

RSpec.describe "Shops", type: :request do
  let(:user) { create(:user) }

  def login_as(user)
    post login_path, params: { email: user.email, password: "password" }
  end

  describe "ログインしていない場合" do
    it "index にアクセスできない" do
      get shops_path

      expect(response).to redirect_to(login_path)
    end

    it "new にアクセスできない" do
      get new_shop_path

      expect(response).to redirect_to(login_path)
    end

    it "create できない" do
      expect do
        post shops_path, params: { shop: { name: "無印良品" } }
      end.not_to change(Shop, :count)

      expect(response).to redirect_to(login_path)
    end
  end

  describe "ログインしている場合" do
    before do
      login_as(user)
    end

    it "index を表示できる" do
      create(:shop, user: user, name: "無印良品")

      get shops_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("無印良品")
    end

    it "Shop を作成できる" do
      expect do
        post shops_path, params: { shop: { name: "楽天市場" } }
      end.to change(user.shops, :count).by(1)

      expect(response).to redirect_to(shops_path)
      expect(user.shops.last.name).to eq("楽天市場")
    end

    it "入力内容が不正な場合は作成に失敗する" do
      expect do
        post shops_path, params: { shop: { name: "" } }
      end.not_to change(Shop, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("ショップ")
    end

    it "edit を表示できる" do
      shop = create(:shop, user: user, name: "編集前ショップ")

      get edit_shop_path(shop)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("編集前ショップ")
    end

    it "Shop を更新できる" do
      shop = create(:shop, user: user, name: "編集前ショップ")

      patch shop_path(shop), params: { shop: { name: "編集後ショップ" } }

      expect(response).to redirect_to(shops_path)
      expect(shop.reload.name).to eq("編集後ショップ")
    end

    it "Shop を削除できる" do
      shop = create(:shop, user: user)

      expect do
        delete shop_path(shop)
      end.to change(user.shops, :count).by(-1)

      expect(response).to redirect_to(shops_path)
    end
  end
end
