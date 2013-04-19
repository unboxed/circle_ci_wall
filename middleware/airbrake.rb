module Goliath
  module Rack
    class Airbrake
      include Goliath::Constants
      include Goliath::Rack::AsyncMiddleware

      def call(env, *args)
        response = super(env, *args)
        if env[RACK_EXCEPTION]
          ::Airbrake.notify(Exception.new("test!!"), :env => ENV)
          ::Airbrake.notify(env[RACK_EXCEPTION], :env => ENV)
        end
        response
      rescue Exception => e
        puts "here2"
        #begin
        #  ::Airbrake.notify_or_ignore(e, :env => env, :paramaters => args)
        #rescue Exception => airbrake_e
        #  puts airbrake_e.message
        #  puts airbrake_e.backtrace.join("\n")
        #end
      end

    end
  end
end