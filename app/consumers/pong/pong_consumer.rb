# frozen_string_literal: true

module Pong
  # Catches the pong and uses PongResponder to respond on a ping topic
  class PongConsumer < ApplicationConsumer
    # Increase counter and respond
    def consume
      data = Handlers::PongHandler.new.handle(params_batch)

      respond_with(data)
    end
  end
end
