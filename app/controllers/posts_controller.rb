# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_post, only: [:show]
  before_action :set_owned_post, only: [:edit, :update, :destroy]

  def index
    @posts = Post.includes(:user, comments: :user).order(created_at: :desc)
  end

  def show; end

  def new
    @post = current_user.posts.build
  end

  def create
    @post = current_user.posts.build(post_params)  # user_id NIE aus params!
    if @post.save
      redirect_to @post, notice: "Post created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @post.update(post_params)
      redirect_to @post, notice: "Post updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @post.destroy
    redirect_to posts_path, notice: "Post deleted."
  rescue ActiveRecord::InvalidForeignKey => e
    redirect_to @post, alert: "Post hat abhängige Kommentare/Replies und konnte nicht gelöscht werden."
  end

  private

  def set_post
    @post = Post.find(params[:id])        # show darf jeder sehen
  end

  # nur eigene Posts für edit/update/destroy
  def set_owned_post
    @post = current_user.posts.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to posts_path, alert: "Du darfst diesen Post nicht bearbeiten."
  end

  def post_params
    params.require(:post).permit(:title, :body)    # user_id NICHT erlauben
  end
end
