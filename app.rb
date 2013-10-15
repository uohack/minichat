require 'sinatra/base'
require 'sinatra/activerecord'
require './models/message'
require 'json'

if ENV['RACK_ENV'] == 'development'
  require 'dotenv'
  Dotenv.load
end

module ChatDemo
  class App < Sinatra::Base
    
    register Sinatra::ActiveRecordExtension

    set :database, ENV['DATABASE_URL']

    get "/" do
      erb :"index.html"
    end

    get "/assets/js/application.js" do
      content_type :js
      @scheme = "ws://" # wss:// if SSL, except we're using a custom domain, so we can't do it :/
      erb :"application.js"
    end

    get '/messages' do
      content_type :json
      Message.order('created_at DESC').take(100).to_json
    end

    get "/thread-stats" do
      content_type :html
      Thread.list.map{|t| t.inspect}.join(", ") + "\n\n" + Thread.current.inspect
    end

  end
end