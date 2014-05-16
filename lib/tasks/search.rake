require 'twitter'
require File.expand_path('./app/helpers/custom_tweets_helper', Rails.root)

module SearchTask
  extend self
  
  def exit
    puts "Exiting"
    exit 1
  end

  def config
    Twitter.configure do |config|
      config.access_token       = TWITTER_CONFIG[:consumer_key]
      config.access_token_secret    = TWITTER_CONFIG[:consumer_secret]
      config.oauth_token        = TWITTER_CONFIG[:oauth_token]
      config.oauth_token_secret = TWITTER_CONFIG[:oauth_token_secret]
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
    include CustomTweetsHelper
    include ErrorHandlers

    def stop
      @client.stop if @client
      exit 1
    end

    # For duplicated statuses on list
    def same_tweet tweet
        response = false
        unless @cached_tweet.nil?
          response = @cached_tweet.eql? tweet.id
        end
        @cached_tweet ||= tweet.id
        response
    end

    def next_search word, q
      sleep(5)
      begin
        search = Twitter.search(word, q)
      rescue Twitter::Error => e
        puts "error: #{e.inspect}"
      rescue Twitter::Error::TooManyRequests => e
        puts "error tmr: #{e.rate_limit}"
      end
    end

    def last_search_query word
      q = {lang: 'es', count: 1, result_type: "recent"}
      if s = ::CustomTweet.where(query: word).last
        id = s.native_id
        puts "#{id}"
        #older
        q = q.merge({max_id: id})
      else
        puts "no"
      end
      q
    end

    # In cases that the database insertion is too expensive that could eventually block the EM event 
    # loop. The status processing block is wrapped inside the EM.defer setup. i.e. The database insertion
    # happens inside one of the thread in EM's thread pool. It runs in the background. It won't block
    # the main EM event loop. But the status might be inserted into the database in an order different
    # from the order that the tweets arrive.
    def search word
      # No need to enclose the following in a EM.run block b/c TweetStream does this when 
      # it initializes the client.
      puts "entering"
      q = last_search_query(word)     
      current_search = next_search(word, q)
      #jump first one beacause of max_id including last one
      q = q.merge(current_search.next_results)
      current_search = next_search(word, q)
      puts "#{current_search.attrs[:search_metadata]}"
      while current_search.next_results? do
        current_search.results.each do |tweet|
          unless same_tweet(tweet)
            raw_tweet_to_tweet(tweet, word).save
          end
        end
        q = q.merge(current_search.next_results)
        current_search = next_search(word, q)
      end
    end
  end
end


task :search, [:word] => [:environment] do |task, args|
  desc "Run Twitter API Search"
  job = SearchTask::Job.new
  trap("SIGINT") { job.stop; SearchTask.exit }
  SearchTask.config do
    job.search "simulacro"
  end
end