class Carrot
  module AMQP
    HEADER        = "AMQP".freeze
    VERSION_MAJOR = 8
    VERSION_MINOR = 0
    PORT          = 5672
  end
end
  
$:.unshift File.expand_path(File.dirname(File.expand_path(__FILE__)))
require 'amqp/spec'
require 'amqp/buffer'
require 'amqp/exchange'
require 'amqp/frame'
require 'amqp/header'
require 'amqp/queue'
require 'amqp/server'
require 'amqp/protocol'

class Carrot
  @logging = false
  class << self
    attr_accessor :logging
  end
  def self.logging?
    @logging
  end
  class Error < StandardError; end

  attr_accessor :server

  def initialize(opts = {})
    @server = AMQP::Server.new(opts)
  end
  
  def queue(name = nil, opts = {})
    return queues[name] if queues.has_key?(name)

    queue = AMQP::Queue.new(self, name, opts)
    queues[queue.name] = queue
  end

  def stop
    server.close
  end

  def queues
    @queues ||= {}
  end

  def direct(name = 'amq.direct', opts = {})
    exchanges[name] ||= AMQP::Exchange.new(self, :direct, name, opts)
  end

  def fanout(name = 'amq.fanout', opts = {})
    exchanges[name] ||= AMQP::Exchange.new(self, :fanout, name, opts)
  end

  def topic(name = 'amq.topic', opts = {})
    exchanges[name] ||= AMQP::Exchange.new(self, :topic, name, opts)
  end

  def headers(name = 'amq.match', opts = {})
    exchanges[name] ||= AMQP::Exchange.new(self, :headers, name, opts)
  end

  def exchanges
    @exchanges ||= {}
  end

private

  def log(*args)
    return unless Carrot.logging?
    pp args
    puts
  end
end

#-- convenience wrapper (read: HACK) for thread-local Carrot object

class Carrot
  def Carrot.default
    #-- XXX clear this when connection is closed
    Thread.current[:carrot] ||= Carrot.new
  end

  # Allows for calls to all Carrot instance methods. This implicitly calls
  # Carrot.new so that a new channel is allocated for subsequent operations.
  def Carrot.method_missing(meth, *args, &blk)
    Carrot.default.__send__(meth, *args, &blk)
  end

end
