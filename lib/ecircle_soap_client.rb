# -*- ruby -*-

require 'savon'
require 'nokogiri'

require 'ecircle/configuration'
require 'ecircle/client'
require 'ecircle/user'

module Ecircle
  extend self

  def configuration
    @configuration ||= Configuration.new
  end

  def client
    @client ||= Client.new
  end

  def configure
    config = configuration
    block_given? ? yield(config) : config
    config
  end
end
