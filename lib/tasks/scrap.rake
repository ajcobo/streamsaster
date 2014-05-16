require 'tweetstream'
require File.expand_path('./app/helpers/tweets_helper', Rails.root)

module ScrapTask
  extend self
  
  def exit
    puts "Exiting"
    exit 1
  end

  def config
    TweetStream.configure do |config|
      config.consumer_key       = TWITTER_CONFIG[:consumer_key]
      config.consumer_secret    = TWITTER_CONFIG[:consumer_secret]
      config.oauth_token        = TWITTER_CONFIG[:oauth_token]
      config.oauth_token_secret = TWITTER_CONFIG[:oauth_token_secret]
      config.auth_method        = :oauth
    end
    puts "configured"
    yield
  end

  module ErrorHandlers

    def error_handler msg
      puts "error handler: #{msg}"
    end

    def reconnect_error_handler timeout, retries
      puts "reconnect_error_handler maximum reconnect #{retries} reached, abort"
      exit 1
    end
  end

  class Job
    include TweetsHelper
    include ErrorHandlers

    def stop
      @client.stop if @client
      exit 1
    end

    # For duplicated statuses on list
    def exclude_cached_status status
      @cached_status ||= {}
      if @cached_status[status.id]
        puts "Warning duplicated status detected"
      else
        @cached_status[status.id] = true
        yield(status)
      end
    end

    # In cases that the database insertion is too expensive that could eventually block the EM event 
    # loop. The status processing block is wrapped inside the EM.defer setup. i.e. The database insertion
    # happens inside one of the thread in EM's thread pool. It runs in the background. It won't block
    # the main EM event loop. But the status might be inserted into the database in an order different
    # from the order that the tweets arrive.
    def stream locations
      # No need to enclose the following in a EM.run block b/c TweetStream does this when 
      # it initializes the client.
      
      puts "entering"
      @client = TweetStream::Client.new.locations(locations) do |status|
        EM.defer do
          exclude_cached_status(status) do
            # We cannot use report_progress as the variable @count is not thread-safe. Performance
            # profiling is little bit more complex that that of the other 2 cases.
            raw_tweet_to_tweet(status)
          end
        end
      end  
    end
  end
end


task :scrap => :environment do
  desc "Run Twitter Scraper"
  job = ScrapTask::Job.new
  trap("SIGINT") { job.stop; ScrapTask.exit }
  ScrapTask.config do
    job.stream [-109.4548925,-56.5356109,-66.3828747,-17.497384] #Chile
  end
end