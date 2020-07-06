class UsersController < ApplicationController
  before_action :logged_in_user, only: [:index, :edit, :update, :destroy,
                                        :following, :followers]
  before_action :correct_user, only:[:edit, :update]
  before_action :admin_user, only: [:destroy]

  def show
    @user = User.find(params[:id])
    # @microposts = @user.microposts.paginate(page: params[:page])
    redirect_to roo_url and return unless @user.activated?
    if params[:q] && params[:q].reject { |key, value| value.blank? }.present?
      @q = @user.microposts.ransack(microposts_search_params)
      @microposts = @q.result.paginate(page: params[:page])
    else 
      @q = Micropost.none.ransack
      @microposts = @user.microposts.paginate(page: params[:page])
    end
    @url = user_path(@user)
  end

  def new
    @user = User.new
  end

  def create 
    @user = User.new(user_params)
    if @user.save
      @user.send_activation_email
      flash[:info] = "Please check your email to activate your account."
      redirect_to root_url
    else
      render 'new' 
    end
  end

  def index
    if params[:q] && params[:q].reject { |key, value| value.blank? }.present?
      @q = User.ransack(search_params, activated: true)
      @title = "Search Result"
    else
      @q = User.ransack(activated: true)
      @title = "All Users"
    end
    @users = @q.result.paginate(page: params[:page])
    # @users = User.where(activated: true).paginate(page: params[:page])
    # @users = User.paginate(page: params[:page])
  end

  def edit
  end

  def update
    if @user.update_attributes(user_params)
      flash[:success] = "Profile updated"
      redirect_to @user
    else
      render 'edit'
    end
  end

  def destroy
    User.find(params[:id]).destroy
    flash[:success] = "User deleted"
    redirect_to users_path
  end

  def following 
    @title = "following"
    @user = User.find(params[:id])
    @users = @user.following.paginate(page: params[:page])
    render 'show_follow'
  end

  def followers
    @title = "followers"
    @user = User.find(params[:id])
    @users = @user.followers.paginate(page: params[:page])
    render 'show_follow'

  end

  private

    def user_params
      params.require(:user).permit(:name, :email, :password, 
                                  :password_confirmation, 
                                  :follow_notification,
                                  :user_name)
    end

    def search_params
      params.require(:q).permit(:name_cont)
    end

    # beforeアクション

    # 正しいユーザーかどうか確認
    def correct_user
      @user = User.find(params[:id])
      redirect_to(root_path)unless current_user?(@user)
    end

    def admin_user
      redirect_to(root_path)unless current_user.admin?
    end

end
