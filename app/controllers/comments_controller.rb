# app/controllers/comments_controller.rb
class CommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_owned_comment, only: [:edit, :update, :destroy]

  def new
    @comment = current_user.comments.build(
      post_id:   params[:post_id],
      parent_id: params[:parent_id] 
    )
  end

  def create
    parent_id = comment_params[:parent_id].presence
    @comment =
      if parent_id
        parent = Comment.find(parent_id)
        current_user.comments.build(
          body:   comment_params[:body],
          post:   parent.post,  
          parent: parent
        )
      else
        current_user.comments.build(comment_params) # enthält :post_id
      end

    if @comment.save
      redirect_to @comment.post, notice: "Comment created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @comment.update(comment_update_params)  
      redirect_to @comment.post, notice: "Comment updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    post = @comment.post
    @comment.destroy
    redirect_to post, notice: "Comment deleted."
  end

  private

  def set_owned_comment
    @comment = current_user.comments.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_back fallback_location: posts_path, alert: "Du darfst diesen Kommentar nicht bearbeiten."
  end

  def comment_params
    params.require(:comment).permit(:body, :post_id, :parent_id) # create
  end

  def comment_update_params
    params.require(:comment).permit(:body)
  end
end
