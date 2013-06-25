module Goliath
  module Rack
    class Airbrake
      include Goliath::Constants
      include Goliath::Rack::AsyncMiddleware

      def call(env, *args)
        response = super(env, *args)
        if env[RACK_EXCEPTION]
          ::Airbrake.notify(env[RACK_EXCEPTION], :env => ENV)
        end
        response
      end

    end
  end
end