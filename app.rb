require 'sinatra/base'

module ChatDemo
  class App < Sinatra::Base
    get "/" do
      erb :"index.html"
    end

    get "/assets/js/application.js" do
      content_type :js
      @scheme = ENV['RACK_ENV'] == "production" ? "ws://" : "ws://"
      erb :"application.js"
    end

    get "/thread-stats" do
      content_type :html
      "<pre>" + Thread.list.map{|t| t.inspect}.join(", ") + "\n\n" + Thread.current.inspect
    end

  end
end