# config/initializers/opentelemetry.rb
require 'opentelemetry/sdk'
require 'opentelemetry/exporter/otlp'
require 'opentelemetry/instrumentation/all'
require_relative '../../lib/opentelemetry/span_processor'

# Create a single instance of the processor
$log_span_processor = LogAttachingSpanProcessor.new

# Configure OpenTelemetry
OpenTelemetry::SDK.configure do |c|
  c.use_all  # Automatically instruments Rails and other libraries
  
  # Use the same processor instance
  c.add_span_processor($log_span_processor)
  
  # Add the OTLP exporter processor
  c.add_span_processor(
    OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(
      OpenTelemetry::Exporter::OTLP::Exporter.new(
        endpoint: 'https://api.honeycomb.io/v1/traces',
        headers: { 'x-honeycomb-team' => ENV.fetch('HONEYCOMB_API_KEY', '') } # Use ENV for security
      )
    )
  )
end

# Monkey patch Rails logger to capture all log messages
module LogCaptureExtension
  %i[debug info warn error fatal].each do |level|
    define_method(level) do |message_or_progname = nil, &block|
      message = block ? block.call : message_or_progname
      puts "DEBUG: Attaching log message: #{message}" # Add debug output
      $log_span_processor.attach_log(message.to_s)
      super(message_or_progname, &block)
    end
  end
end

Rails.logger.singleton_class.prepend(LogCaptureExtension)

MyAppTracer = OpenTelemetry.tracer_provider.tracer('ruby-opentelemetry-test')
