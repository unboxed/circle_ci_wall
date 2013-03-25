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

fiber_pool = FiberPool.new(4)

Goliath::Request.execute_block = proc do |&block|
  fiber_pool.spawn(&block)
end

class HelloWorld < Goliath::API
  CIRCLE_BASE_URL = "https://circleci.com/api/v1/"
  include Goliath::Rack::Templates      # render templated files from ./views

  use(Rack::Static,                     # render static files from ./public
      :root => Goliath::Application.app_path("public"),
      :urls => ["/favicon.ico", '/stylesheets', '/javascripts', '/images'])

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