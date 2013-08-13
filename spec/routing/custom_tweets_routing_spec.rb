require "spec_helper"

describe CustomTweetsController do
  describe "routing" do

    it "routes to #index" do
      get("/custom_tweets").should route_to("custom_tweets#index")
    end

    it "routes to #new" do
      get("/custom_tweets/new").should route_to("custom_tweets#new")
    end

    it "routes to #show" do
      get("/custom_tweets/1").should route_to("custom_tweets#show", :id => "1")
    end

    it "routes to #edit" do
      get("/custom_tweets/1/edit").should route_to("custom_tweets#edit", :id => "1")
    end

    it "routes to #create" do
      post("/custom_tweets").should route_to("custom_tweets#create")
    end

    it "routes to #update" do
      put("/custom_tweets/1").should route_to("custom_tweets#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/custom_tweets/1").should route_to("custom_tweets#destroy", :id => "1")
    end

  end
end
