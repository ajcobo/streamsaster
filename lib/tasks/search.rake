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
      config.consumer_key       = TWITTER_CONFIG[:consumer_key]
      config.consumer_secret    = TWITTER_CONFIG[:consumer_secret]
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
    def exclude_cached_status status
      @cached_status ||= {}
      if @cached_status[status.id]
        puts "Warning duplicated status detected"
        puts "Ignoring"
      else
        @cached_status[status.id] = true
        yield(status)
      end
    end

    def next_search word, q
      begin
        search = Twitter.search(word, q)
      rescue Twitter::Error => e
        puts e.inspect
      rescue Twitter::Error::TooManyRequests => e
        puts e.rate_limit
      end
    end

    def last_search_query word
      q = {lang: 'es', count: 1}
      if id = ::CustomTweet.where(query: word).last.native_id
        puts "yes"
        q.merge({id: id})
      else
        puts "no"
        q
      end
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
      current_search = Twitter.search(word, q)
      while current_search.next_results? do
        current_search.results.each do |tweet|
          exclude_cached_status(tweet) do
            # We cannot use report_progress as the variable @count is not thread-safe. Performance
            # profiling is little bit more complex that that of the other 2 cases.
            raw_tweet_to_tweet(tweet, word).save
          end
        end
        q = q.merge(current_search.next_results)
        sleep(5)
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
    job.search args.word
  end
end