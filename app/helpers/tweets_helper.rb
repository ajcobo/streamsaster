module TweetsHelper

	def raw_tweet_to_tweet status
	  puts "#{status.text}"
	  id = status.id
	  unless status.geo.nil?
	    longitude = status.geo.coordinates[1].to_f
	    latitude = status.geo.coordinates[0].to_f
	  else
	    longitud = nil
	    latitude = nil
	  end
	  retweet_count = status.retweet_count
	  author = status.user
	  user = author.screen_name
	  location = author.location
	  profile_image_url = author.profile_image_url
	  created_at = status.created_at
	  statuses_count = author.statuses_count
	  friends_count = author.friends_count
	  ::Tweet.new(native_id: id, text: status.text, coordinates: [longitude, latitude], 
	                 retweet_count: retweet_count, user: user, location: location, profile_image_url: profile_image_url, 
	                 created_at: created_at, statuses_count: statuses_count, friends_count: friends_count)
	end
	
end
