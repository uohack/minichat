require 'faye/websocket'
require 'thread'
require 'redis'
require 'json'
require 'erb'

module ChatDemo
  class ChatBackend
    KEEPALIVE_TIME = 15 # in seconds
    CHANNEL        = "chat-demo"

    def initialize(app)
      @app     = app
      @clients = []
      
      if !ENV["REDISTOGO_URL"].nil?
        uri = URI.parse(ENV["REDISTOGO_URL"])
        @redis = Redis.new(host: uri.host, port: uri.port, password: uri.password)
      else
        @redis = Redis.new
      end

      Thread.new do         
         if !ENV["REDISTOGO_URL"].nil?
          uri = URI.parse(ENV["REDISTOGO_URL"])
          redis_sub = Redis.new(host: uri.host, port: uri.port, password: uri.password)
        else
          redis_sub = Redis.new
        end
        redis_sub.subscribe(CHANNEL) do |on|
          on.message do |channel, msg|
            @clients.each {|ws| ws.send(msg) }
          end
        end
      end

    end

    def call(env)
      if Faye::WebSocket.websocket?(env)
        ws = Faye::WebSocket.new(env, nil, {ping: KEEPALIVE_TIME })
        ws.on :open do |event|
          p [:open, ws.object_id]
          @clients << ws
        end

        ws.on :message do |event|
          p [:message, event.data]
          sanitized_data = sanitize(event.data)
          
          puts sanitized_data

          ActiveRecord::Base.connection_pool.with_connection do
            message = Message.create(handle: sanitized_data['handle'], body: sanitized_data['body'])
            if message
              @redis.publish(CHANNEL, JSON.generate(sanitized_data))
            else
              p "error creating message: #{sanitized_data}"
            end
          end          
        end

        ws.on :close do |event|
          p [:close, ws.object_id, event.code, event.reason]
          @clients.delete(ws)
          ws = nil
        end

        # Return async Rack response
        ws.rack_response

      else
        @app.call(env)
      end
    end

    private
    def sanitize(message)
      json = JSON.parse(message)
      json.each {|key, value| json[key] = ERB::Util.html_escape(value) }      
    end
  end
end
