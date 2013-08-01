require 'tweetstream'

def config
  TweetStream.configure do |config|
    config.consumer_key       = TWITTER_CONFIG[:consumer_key]
    config.consumer_secret    = TWITTER_CONFIG[:consumer_secret]
    config.oauth_token        = TWITTER_CONFIG[:oauth_token]
    config.oauth_token_secret = TWITTER_CONFIG[:oauth_token_secret]
    config.auth_method        = :oauth
  end
  puts "configured"
end

def error_handler msg
  puts "error handler: #{msg}"
end

def reconnect_error_handler timeout, retries
  puts "reconnect_error_handler maximum reconnect #{retries} reached, abort"
  exit 1
end
#based on lonex/geo_tweet

def exclude_cached_status status
  @cached_status ||= {}
  if @cached_status[status.id]
    puts "Warning duplicated status detected"
  else
    @cached_status[status.id] = true
    yield(status)
  end
end

def stop
  @client.stop if @client
  exit 1
end

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
  author = status.user
  user = author.screen_name
  location = author.location
  profile_image_url = author.profile_image_url
  created_at = status.created_at
  ::Tweet.new(native_id: id, text: status.text, coordinates: [longitude, latitude], 
                 user: user, location: location, profile_image_url: profile_image_url, created_at: created_at)
end

# In cases that the database insertion is too expensive that could eventually block the EM event 
# loop. The status processing block is wrapped inside the EM.defer setup. i.e. The database insertion
# happens inside one of the thread in EM's thread pool. It runs in the background. It won't block
# the main EM event loop. But the status might be inserted into the database in an order different
# from the order that the tweets arrive.
def stream locations
  # No need to enclose the following in a EM.run block b/c TweetStream does this when 
  # it initializes the client.
  @client = TweetStream::Client.new
  @client.on_limit do |discarded_count|
    puts "RATE LIMIT #{discarded_count}"
  end
  @client.locations(locations) do |status|
    EM.defer do
      exclude_cached_status(status) do
        # We cannot use report_progress as the variable @count is not thread-safe. Performance
        # profiling is little bit more complex that that of the other 2 cases.
        raw_tweet_to_tweet(status).save
      end
    end
  end  
end

task :scrap => :environment do
  desc "Run Twitter Scraper"
  config do
    stream [-70.16899108886719,-20.30148555739852,-70.08110046386719,-20.184879384574092] #Iquique 
  end
end
