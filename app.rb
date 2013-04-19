require 'rubygems'
require 'bundler/setup'

require 'erb'
require 'tilt'
require 'json'
require 'em-synchrony/em-http'
require 'goliath'
require 'goliath/rack/templates'
require 'goliath/plugins/latency'
require 'fiber_pool'
require 'airbrake'
require './middleware/airbrake'
# require 'logger'

Airbrake.configure do |config|
  config.api_key = ENV['AIRBRAKE_API_KEY']
  config.host    = ENV['AIRBRAKE_HOST']
  config.async do |notice|
    Thread.new { Airbrake.sender.send_to_airbrake(notice) }
  end
  #config.development_environments = []
  #config.logger = Logger.new(STDOUT)
end

fiber_pool = FiberPool.new(4)

Goliath::Request.execute_block = proc do |&block|
  fiber_pool.spawn(&block)
end

class HelloWorld < Goliath::API
  CIRCLE_BASE_URL = "https://circleci.com/api/v1/"
  use Goliath::Rack::Airbrake
  include Goliath::Rack::Templates      # render templated files from ./views

  use(Rack::Static,                     # render static files from ./public
      :root => Goliath::Application.app_path("public"),
      :urls => ["/favicon.ico", '/style.css', '/javascripts', '/images'])

  # plugin Goliath::Plugin::Latency       # ask eventmachine reactor to track its latency

  #def recent_latency
  #  Goliath::Plugin::Latency.recent_latency
  #end

  def response(env)
    resp = EM::HttpRequest.new(CIRCLE_BASE_URL + "project/contikiholidays/contiki").
             get(head: {"Accept" => "application/json"},
                 query: {'circle-token' => '9bcff994b2e3a6c873aa28eff9f325315ee143de'})

    if resp.response_header.status.to_i != 0
      begin
        @branches = JSON.parse(resp.response).group_by{|i| i['branch']}
      rescue Exception => e
        @error = e.message
      end
    else
      @error = resp.error
    end

    [200, {}, erb(:index)]
  end
end