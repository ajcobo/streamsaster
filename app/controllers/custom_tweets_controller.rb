class CustomTweetsController < ApplicationController
  # GET /custom_tweets
  # GET /custom_tweets.json
  def index
    @custom_tweets = CustomTweet.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @custom_tweets }
    end
  end

  # GET /custom_tweets/1
  # GET /custom_tweets/1.json
  def show
    @custom_tweet = CustomTweet.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @custom_tweet }
    end
  end

  # GET /custom_tweets/new
  # GET /custom_tweets/new.json
  def new
    @custom_tweet = CustomTweet.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @custom_tweet }
    end
  end

  # GET /custom_tweets/1/edit
  def edit
    @custom_tweet = CustomTweet.find(params[:id])
  end

  # POST /custom_tweets
  # POST /custom_tweets.json
  def create
    @custom_tweet = CustomTweet.new(params[:custom_tweet])

    respond_to do |format|
      if @custom_tweet.save
        format.html { redirect_to @custom_tweet, notice: 'Custom tweet was successfully created.' }
        format.json { render json: @custom_tweet, status: :created, location: @custom_tweet }
      else
        format.html { render action: "new" }
        format.json { render json: @custom_tweet.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /custom_tweets/1
  # PUT /custom_tweets/1.json
  def update
    @custom_tweet = CustomTweet.find(params[:id])

    respond_to do |format|
      if @custom_tweet.update_attributes(params[:custom_tweet])
        format.html { redirect_to @custom_tweet, notice: 'Custom tweet was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @custom_tweet.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /custom_tweets/1
  # DELETE /custom_tweets/1.json
  def destroy
    @custom_tweet = CustomTweet.find(params[:id])
    @custom_tweet.destroy

    respond_to do |format|
      format.html { redirect_to custom_tweets_url }
      format.json { head :no_content }
    end
  end
end
