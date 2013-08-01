class HomeController < ApplicationController
  def index
    @json = Tweet.all.to_gmaps4rails do |tweet, marker|
      marker.picture({
                      :picture => "http://www.blankdots.com/img/github-32x32.png",
                      :width   => 32,
                      :height  => 32
                     })
      marker.title   "i'm the title"
      marker.sidebar "i'm the sidebar"
      marker.json({ :id => tweet.id, :foo => "bar" })
    end
  end
end
