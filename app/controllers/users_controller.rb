class UsersController < ApplicationController
  def new
    @sign_up_form = SignUpForm.new
  end

  def create
    @sign_up_form = SignUpForm.new(sign_up_form_params)
    if @sign_up_form.valid?
      user = User.new(name: @sign_up_form.name, email: @sign_up_form.email, password: @sign_up_form.password)

      if user.save
        session[:user_id] = user.id
        redirect_to posts_path, success: 'サインアップしました'
      else
        flash.now[:danger] = 'ユーザーの作成に失敗しました'
        render :new
      end
    else
      flash.now[:danger] = 'サインアップに失敗しました'
      render :new
    end
  end

  def user_params
    params.require(:user).permit(:email, :password, :name) # name を追加
  end

  private

  def sign_up_form_params
    params.require(:sign_up_form).permit(:email, :password, :password_confirmation, :name)
  end
end
