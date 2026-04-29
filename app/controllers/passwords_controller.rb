class PasswordsController < ApplicationController
  skip_before_action :require_login
  before_action :set_user_from_token, only: %i[edit update]

  def new; end

  def create
    user = User.find_by(email: params[:email].to_s.downcase)

    PasswordsMailer.reset_password(user).deliver_now if user.present?

    redirect_to login_path, notice: t("flash.password.create")
  end

  def edit
    @token = params[:token]
  end

  def update
    @token = params[:token]

    if @user.update(password_params)
      redirect_to login_path, notice: t("flash.password.update")
    else
      flash.now[:alert] = t("flash.password.update_failure")
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end

  def set_user_from_token
    @user = User.find_by_password_reset_token!(params[:token])
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    redirect_to new_password_path, alert: t("flash.password.invalid_token")
  end
end
