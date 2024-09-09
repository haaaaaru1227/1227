class SignUpForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  
  attribute :email, :string
  attribute :password, :string
  attribute :password_confirmation, :string
  attribute :name, :string

  # バリデーション
  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 3 }, confirmation: true
  validate :name_exists_on_github
  validate :email_is_not_taken_by_another

  def save
    return false if invalid?

    ActiveRecord::Base.transaction do
      user.save!  # ユーザーを保存
      Profile.create!(name: name, user: user)  # プロフィールを作成
    end
  rescue StandardError
    false
  end

  def user
    @user ||= User.new(email: email, password: password, password_confirmation: password_confirmation)
  end

  private

  # GitHubでユーザー名が存在するか確認するメソッド
  def name_exists_on_github
    github_url = "https://github.com/#{name}"
    uri = URI.parse(github_url)

    # HEADリクエストを使って確認
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      http.head(uri.path)
    end

    # ステータスコードが404の場合はバリデーションエラー
    if response.is_a?(Net::HTTPNotFound)
      errors.add(:name, 'はGitHubに存在するユーザー名しか登録できません')
    end
  end

  # メールアドレスが既に登録されていないか確認
  def email_is_not_taken_by_another
    errors.add(:email, :taken, value: email) if User.exists?(email: email)
  end
end
