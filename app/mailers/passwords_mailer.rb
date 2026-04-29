class PasswordsMailer < ApplicationMailer
  def reset_password(user)
    @user = user
    @reset_url = edit_password_url(token: @user.password_reset_token)

    mail(to: @user.email, subject: "パスワード再設定のご案内")
  end
end
