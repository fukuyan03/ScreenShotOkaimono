class SessionsController < ApplicationController
  skip_before_action :require_login, only: %i[new create omniauth failure]

  def new; end

  def create
    user = User.find_by(email: params[:email])
    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      redirect_to shops_path, notice: t("flash.login.success")
    else
      flash.now[:alert] = t("flash.login.failure")
      render :new, status: :unprocessable_entity
    end
  end

  def omniauth
    auth = request.env["omniauth.auth"]
    email = auth.info.email.to_s.downcase

    user = User.find_by(provider: auth.provider, uid: auth.uid) ||
           User.find_or_initialize_by(email: email)

    user.provider = auth.provider
    user.uid = auth.uid

    if user.new_record?
      user.name = auth.info.name
      user.email = email
      user.password = SecureRandom.urlsafe_base64
    end

    if user.save
      session[:user_id] = user.id
      redirect_to shops_path, notice: "Googleアカウントでログインしました"
    else
      redirect_to login_path, alert: "Googleログインに失敗しました"
    end
  end

  def failure
    redirect_to login_path, alert: "Googleログインに失敗しました"
  end

  def destroy
    session.delete(:user_id)
    redirect_to login_path, notice: t("flash.login.logout")
  end
end
