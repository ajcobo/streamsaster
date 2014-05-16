class TweetSerializer < ActiveModel::Serializer
  attributes :id, :user, :content, :coordinates
end
