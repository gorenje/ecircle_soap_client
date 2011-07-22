# -*- ruby -*-

require 'savon'
require 'nokogiri'
require 'net/http/post/multipart'
require 'uuidtools'
require 'base64'
require 'ostruct'

require 'ecircle/configuration'
require 'ecircle/client'
require 'ecircle/base'
require 'ecircle/member'
require 'ecircle/group'
require 'ecircle/user'
require 'ecircle/message'

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
