class CustomTweet
  include Mongoid::Document
  include Gmaps4rails::ActsAsGmappable

  #Tweet
  field :native_id, type: String
  field :text, type: String
  field :coordinates, type: Array
  field :retweet_count, type: Integer

  #query
  field :query, type: String
  
  #User
  field :created_at, type: DateTime
  field :user, type: String
  field :location, type: String
  field :profile_image_url, type: String
  field :followers_count, type: Integer
  field :lang, type: String
  field :statuses_count, type: Integer
  field :friends_count, type: Integer

  #Validations
  validates_presence_of :native_id, :allow_nil => false

  def permalink
    "https://twitter.com/#!/%s" % user
  end
  
  def tweet_permalink 
    "https://twitter.com/%s/status/%s" % [user, native_id]
  end
end
