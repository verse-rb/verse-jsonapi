class UserRecord < Verse::Model::Record::Base
  field :id, primary: true, type: :int
  field :name, type: String

  has_many :posts
  has_many :comments
  has_one  :account
end

class PostRecord < Verse::Model::Record::Base
  field :id, primary: true, type: :int

  field :user_id, visible: false

  field :title, type: :string
  field :content, type: :string

  field :secret_field, type: :string, visible: false

  belongs_to :user
  has_many :comments
end

class CommentRecord < Verse::Model::Record::Base
  field :id, primary: true

  field :user_id
  field :post_id

  field :content, type: :string

  belongs_to :user
  belongs_to :post
end