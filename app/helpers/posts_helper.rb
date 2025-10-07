module PostsHelper
  def anonymize_author_for(post)
    if user_signed_in?
      post.author.name
    else
      "Anonymous"
    end
  end
end
