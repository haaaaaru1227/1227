class PostsController < ApplicationController
  before_action :require_login, only: %i[new create]
  before_action :set_search, only: %i[index new create edit show search]

  def index
    @q = Post.ransack(params[:q])
    @posts = @q.result(distinct: true).includes(:user).order(created_at: :desc).page(params[:page]).per(10)
    @tags = Tag.all
  end

  def new
    @post = Post.new
    @tag = Tag.new
  end

  def create
    @post = current_user.posts.new(post_params)

    if @post.save
      @post.save_tag(params[:post][:tag_name]) if params[:post][:tag_name].present?
      redirect_to post_path(@post), success: 'ポストを作成しました'
    else
      flash.now[:danger] = 'ポストを作成できませんでした'
      render :new
    end
  end

  def show
    @post = Post.find(params[:id])
    @tags = @post.tags
    @comment = Comment.new
  end

  def edit
    @post = current_user.posts.find(params[:id])
  end

  def update
    @post = current_user.posts.find(params[:id])

    if @post.update(post_params)
      @post.save_tag(params[:post][:tag_name]) if params[:post][:tag_name].present?
      redirect_to post_path(@post), success: 'ポストを更新しました'
    else
      flash.now[:danger] = 'ポストを更新できませんでした'
      render :edit
    end
  end

  def destroy
    @post = current_user.posts.find(params[:id])
    @post.destroy!
    redirect_to posts_path, success: 'ポストを削除しました'
  end

  def search
    @posts = Post.search(params)

    # タグ検索時は件数を表示しない
    if params[:tag_id].present? || (params[:q] && params[:q][:tags_name_cont].present?)
      @show_search_count = false
    else
      @show_search_count = @posts.any?
    end

      render :search
  end
  
  private

  def set_search
    @q = Post.ransack(params[:q])
  end

  def post_params
    params.require(:post).permit(:title, :body)
  end

  def process_tags
    return if params[:post][:tag_name].blank?

    tag_names = params[:post][:tag_name].split(',').map(&:strip)
    tag_names.each do |name|
      tag = Tag.find_or_create_by(name: name)
      @post.tags << tag unless @post.tags.include?(tag)
    end
  end
end
