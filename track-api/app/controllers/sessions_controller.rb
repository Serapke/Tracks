class SessionsController < ApplicationController

  def create
    user_email = params[:session][:email]
    user_password = params[:session][:password]

    @user = user_email.present? && User.find_by(email: user_email)

    if @user && @user.valid_password?(user_password) then
      sign_in_and_generate_token
      @user.save
      render json: @user, status: 200
    else
      render json: { errors: "Incorrect credentials" }, status: 422
    end
  end

  def destroy
    user = User.find_by(auth_token: params[:id])
    user.generate_authentication_token!
    user.save
    head 204
  end

  private

  def sign_in_and_generate_token
    sign_in @user, store: false
    @user.generate_authentication_token!
  end
end
