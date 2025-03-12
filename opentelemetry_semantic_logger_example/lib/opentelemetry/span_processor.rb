# lib/opentelemetry/span_processor.rb
require 'opentelemetry/sdk'

class LogAttachingSpanProcessor < OpenTelemetry::SDK::Trace::SpanProcessor
  def initialize
    @mutex = Mutex.new
    @active_spans = {}
    @log_counters = {}  # Track number of logs per span
  end

  def on_start(span, parent_context)
    @mutex.synchronize do
      @active_spans[Thread.current.object_id] = span
      @log_counters[span.context.span_id] = 0
    end
  end

  def on_end(span)
    @mutex.synchronize do
      @active_spans.delete(Thread.current.object_id)
      @log_counters.delete(span.context.span_id)
    end
  end

  def attach_log(message)
    @mutex.synchronize do
      if span = @active_spans[Thread.current.object_id]
        counter = @log_counters[span.context.span_id] += 1
        puts "Attempting to attach log #{counter}: #{message} to span: #{span.name}"
        span.set_attribute("log.message.#{counter}", message.to_s)
      else
        puts "No active span found for thread: #{Thread.current.object_id}"
      end
    end
  end

  # Required SpanProcessor methods that we don't need to modify
  def shutdown; end
  def force_flush; end
end
