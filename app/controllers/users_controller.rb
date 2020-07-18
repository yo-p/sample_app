class UsersController < ApplicationController
  before_action :logged_in_user, only: [:index, :edit, :update, :destroy,
                                        :following, :followers]
  before_action :get_user, only: [:show, :destroy, :following, :followers]
  before_action :correct_user, only:[:edit, :update]
  before_action :admin_user, only: [:destroy]

  def show
    redirect_to root_url and return unless @user.activated?
    if params[:q] && params[:q].reject { |key, value| value.blank? }.present?
      @q = @user.microposts.ransack(microposts_search_params)
      @microposts = @q.result.paginate(page: params[:page])
    else 
      @q = Micropost.none.ransack
      @microposts = @user.microposts.paginate(page: params[:page])
    end
    @room_id = message_room_id(current_user, @user)
    @messages = Message.recent_in_room(@room_id)
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
    @user.destroy
    flash[:success] = "User deleted"
    redirect_to users_path
  end

  def following 
    @title = "following"
    @users = @user.following.paginate(page: params[:page])
    render 'show_follow'
  end

  def followers
    @title = "followers"
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

    # before_action

    # Search user from database by user id
    def get_user
      @user = User.find(params[:id])
    end

    
    def search_params
      params.require(:q).permit(:name_cont)
    end

    # Check if the user is authorized to do the action
    def correct_user
      @user ||= get_user
      redirect_to(root_path)unless current_user?(@user)
    end

    # Check if the user is administraor
    def admin_user
      redirect_to(root_path)unless current_user.admin?
    end

    # Return room ide
    def message_room_id(first_user, second_user)
      first_id = first_user.id.to_i
      second_id = second_user.id.to_i
      if first_id < second_id
        "#{first_user.id}-#{second_user.id}"
      else
        "#{second_user.id}-#{first_user.id}"
      end
    end
end
