class AccountsController < ApplicationController
  def show
  end

  def update
    if params[:password].present?
      update_password
    else
      update_profile
    end
  end

  private

  def update_profile
    if Current.user.update(profile_params)
      redirect_to account_path, notice: "Account updated."
    else
      render :show, status: :unprocessable_entity
    end
  end

  def update_password
    unless Current.user.authenticate(params[:current_password])
      Current.user.errors.add(:current_password, "is incorrect")
      render :show, status: :unprocessable_entity
      return
    end

    if Current.user.update(password_params)
      redirect_to account_path, notice: "Password changed."
    else
      render :show, status: :unprocessable_entity
    end
  end

  def profile_params
    params.require(:user).permit(:name, :email_address)
  end

  def password_params
    params.permit(:password, :password_confirmation)
  end
end
