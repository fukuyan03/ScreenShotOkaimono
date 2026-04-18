require "rails_helper"

RSpec.describe "Items", type: :request do
  let(:user) { create(:user) }
  let(:shop) { create(:shop, user: user, name: "無印良品") }

  def login_as(user)
    post login_path, params: { email: user.email, password: "password" }
  end

  def uploaded_image
    file = Tempfile.new(["item", ".png"])
    file.binmode
    file.write("dummy image")
    file.rewind

    Rack::Test::UploadedFile.new(file.path, "image/png")
  end

  describe "ログインしていない場合" do
    it "index にアクセスできない" do
      get shop_items_path(shop)

      expect(response).to redirect_to(login_path)
    end

    it "new にアクセスできない" do
      get new_shop_item_path(shop)

      expect(response).to redirect_to(login_path)
    end

    it "show にアクセスできない" do
      item = create(:item, shop: shop)

      get shop_item_path(shop, item)

      expect(response).to redirect_to(login_path)
    end

    it "create できない" do
      expect do
        post shop_items_path(shop), params: { item: { name: "スリッパ" } }
      end.not_to change(Item, :count)

      expect(response).to redirect_to(login_path)
    end
  end

  describe "ログインしている場合" do
    before do
      login_as(user)
    end

    it "index を表示できる" do
      create(:item, shop: shop, name: "スリッパ")

      get shop_items_path(shop)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("スリッパ")
    end

    it "new を表示できる" do
      get new_shop_item_path(shop)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("商品登録")
    end

    it "show を表示できる" do
      item = create(:item, shop: shop, name: "スリッパ")

      get shop_item_path(shop, item)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("スリッパ")
    end

    it "Item を作成できる" do
      item_params = {
        name: "スリッパ",
        brand: "無印良品",
        price: 1990,
        summary: "シンプルな室内用スリッパ",
        source_platform: "Instagram",
        source_author_name: "muji",
        status: "want"
      }

      expect do
        post shop_items_path(shop), params: { item: item_params }
      end.to change(shop.items, :count).by(1)

      expect(response).to redirect_to(shop_items_path(shop))
      expect(shop.items.last.name).to eq("スリッパ")
    end

    it "Item を更新できる" do
      item = create(:item, shop: shop, name: "スリッパ")

      patch shop_item_path(shop, item), params: { item: { name: "サンダル", status: "purchased" } }

      expect(response).to redirect_to(shop_items_path(shop))
      expect(item.reload.name).to eq("サンダル")
      expect(item).to be_purchased
    end

    it "Item を削除できる" do
      item = create(:item, shop: shop)

      expect do
        delete shop_item_path(shop, item)
      end.to change(shop.items, :count).by(-1)

      expect(response).to redirect_to(shop_items_path(shop))
    end

    it "画像ありで AI解析が動く" do
      allow(ItemImageAnalyzer).to receive(:call).and_return(
        {
          name: "スリッパ",
          brand: "無印良品",
          price: 1990,
          summary: "シンプルな室内用スリッパ",
          source_platform: "Instagram",
          source_author_name: "muji",
          shop_candidates: ["無印良品"]
        }
      )

      post analyze_shop_items_path(shop), params: { item: { image: uploaded_image } }

      expect(ItemImageAnalyzer).to have_received(:call)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("スリッパ")
      expect(response.body).to include("無印良品")
    end

    it "画像なしの AI解析は失敗する" do
      expect(ItemImageAnalyzer).not_to receive(:call)

      post analyze_shop_items_path(shop), params: { item: { name: "" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("商品登録")
    end
  end
end
