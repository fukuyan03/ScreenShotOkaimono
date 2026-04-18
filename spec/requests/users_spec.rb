require "rails_helper"

RSpec.describe "Users", type: :request do
  describe "GET /users/new" do
    it "新規登録画面を表示できる" do
      get new_user_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("新規登録")
    end
  end

  describe "POST /users" do
    it "ユーザー登録できる" do
      user_params = {
        name: "山田太郎",
        email: "taro@example.com",
        password: "password",
        password_confirmation: "password"
      }

      expect do
        post users_path, params: { user: user_params }
      end.to change(User, :count).by(1)

      expect(response).to redirect_to(root_path)
      expect(User.last.email).to eq("taro@example.com")
    end

    it "入力内容が不正な場合は登録に失敗する" do
      invalid_params = {
        name: "",
        email: "invalid-email",
        password: "password",
        password_confirmation: "different"
      }

      expect do
        post users_path, params: { user: invalid_params }
      end.not_to change(User, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("新規登録")
    end
  end
end
