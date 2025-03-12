# app/controllers/hello_controller.rb
require 'ostruct'
require 'opentelemetry/sdk'

class HelloController < ApplicationController
  def index
    MyAppTracer.in_span('Starter span', attributes: { "hello" => "world", "some.number" => 1024 }) do 

    # Simulate fetching a user (replace this with actual user fetching logic)
    user = OpenStruct.new(id: 123)  # Example user
    # Log a message that will be attached to the span
    logger.info "User #{user.id} accessed the hello endpoint"
    current_span = OpenTelemetry::Trace.current_span
    current_span.set_attribute('user_id', user.to_s)

    render plain: "Hello, World!"
    end
  end 
end
