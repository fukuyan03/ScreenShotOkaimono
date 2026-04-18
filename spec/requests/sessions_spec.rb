require "rails_helper"

RSpec.describe "Sessions", type: :request do
  let!(:user) { create(:user, email: "login@example.com", password: "password", password_confirmation: "password") }

  describe "GET /login" do
    it "ログイン画面を表示できる" do
      get login_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("ログイン")
    end
  end

  describe "POST /login" do
    it "正しいメールアドレスとパスワードでログインできる" do
      post login_path, params: { email: user.email, password: "password" }

      expect(response).to redirect_to(shops_path)
    end

    it "誤った情報ではログインに失敗する" do
      post login_path, params: { email: user.email, password: "wrong-password" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("ログイン")
    end
  end

  describe "DELETE /logout" do
    it "ログアウトできる" do
      post login_path, params: { email: user.email, password: "password" }

      delete logout_path

      expect(response).to redirect_to(login_path)
    end
  end
end
