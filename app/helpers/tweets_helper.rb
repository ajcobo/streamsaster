module TweetsHelper

	def raw_tweet_to_tweet status
		::Twitter.collection.insert status.to_h
	end
end
