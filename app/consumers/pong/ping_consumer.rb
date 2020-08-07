# frozen_string_literal: true

# Namespace for everything related to our small ping-pong game
module Pong
  # Catches the ping and uses PingResponder to respond on a pong topic
  class PingConsumer < ApplicationConsumer
    # We increase the pings counter and respond
    def consume
      # The initial ping needs to be triggered via the rake task
      data = Handlers::PongHandler.new.handle(params_batch)

      respond_with(data)
    end
  end
end
