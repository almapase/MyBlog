class CommentsController < ApplicationController
  def create
    @post = Post.find(params[:post_id])
    @comment = @post.comments.build(comments_params)
    if @comment.save
      redirect_to @post, notice: "El comentario fue creado corectamente"
    else
      redirect_to @post, alert: "El comentario no fue creado"
    end
  end

  private
  def comments_params
    params.require(:comment).permit(:comment)
  end
end
