class MicropostsController < ApplicationController
    before_action :logged_in_user, only: [:create, :destroy]
    before_action :correct_user, only: [:destroy]

    def create
        @micropost = current_user.microposts.build(micropost_params)
        reply = /@([0-9a-z_]{5,15})/i
        @micropost.content.match(reply)
        if @micropost.save
            flash[:success] = "Micropost created!"
            redirect_to root_path
        else
            @q = Micropost.none.ransack
            @feed_items = current_user.feed.paginate(page: params[:page])
            render 'static_pages/home'
        end
    end

    def destroy
        @micropost.destroy
        flash[:success] = "Micropost deleted"
        # redirect_to request.referrer || root_path
        redirect_back(fallback_location: root_path)
    end

private

    def micropost_params
        params.require(:micropost).permit(:content, :picture)
    end

    def correct_user
        @micropost = current_user.microposts.find_by(id: params[:id])
        redirect_to root_path if @micropost.nil?
    end
end
