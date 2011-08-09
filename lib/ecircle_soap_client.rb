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

# Helper for converting times to ecircle expected format.
module EcircleTimeHelper
  def ecircle_format(prefix)
    # ecircle uses JS month indices
    strftime("yyyy:%Y,dd:%d,hh:%H,min:%M,ss:%S,mm:#{'%02d' % (month - 1)}").split(',').
      inject({}) do |hsh, postfix_and_value|
      postfix, value = postfix_and_value.split(':')
      hsh.merge( "#{prefix}_#{postfix}".to_sym => value )
    end
  end
end

[Date, Time].each do |clazz|
  clazz.send(:include, EcircleTimeHelper)
end

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
