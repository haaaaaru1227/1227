class Post < ApplicationRecord
  belongs_to :user
  has_many :comments, dependent: :destroy
  has_many :post_tags, dependent: :destroy
  has_many :tags, through: :post_tags

  validates :title, presence: true
  validates :body, presence: true

  def save_tag(tag_names)
    return unless tag_names.present?
  
    tag_names = tag_names.split(',').map(&:strip) if tag_names.is_a?(String)
    current_tags = self.tags.pluck(:name)
  
    old_tags = current_tags - tag_names
    new_tags = tag_names - current_tags
  
    old_tags.each do |old|
      tag = Tag.find_by(name: old)
      self.tags.delete(tag) if tag
    end
  
    new_tags.each do |new_tag|
      post_tag = Tag.find_or_create_by(name: new_tag)
      self.tags << post_tag
    end
  end

  def self.search(params)
    search_params = params[:q] || {}

    # タグIDによる絞り込みを最初に処理
    if params[:tag_id].present?
      tag = Tag.find_by(id: params[:tag_id])
      return Post.none unless tag
      return Post.joins(:tags).where(tags: { id: tag.id }).distinct.page(params[:page])
    end

    # ベースの検索オブジェクトを作成
    @q = Post.ransack(
      title_or_body_cont: search_params[:title_or_body_cont],
      comments_body_cont: search_params[:comments_body_cont]
    )

    # 基本的な検索結果
    posts = @q.result(distinct: true).includes(:comments, :user, :tags)

    # タグ名による曖昧検索

    if search_params[:user_name_cont].present?
      profiles = Profile.where("name LIKE ?", "%#{search_params[:user_name_cont]}%")
      user_ids = profiles.pluck(:user_id)
  
      # ユーザー名に一致する投稿だけを残す
      posts = posts.where(user_id: user_ids) if user_ids.any?
    end

    # ページングを適用
    posts.page(params[:page])
  end

end
