require 'ostruct'
module Ecircle
  class Configuration
    attr_accessor :realm, :user, :password, :wsdl, :use_priority

    def initialize
      @session_token = nil
      @use_priority = false
      @wsdl = OpenStruct.new
      wsdl.document = "http://webservices.ecircle-ag.com/soap/ecm.wsdl"
      wsdl.endpoint = "http://webservices.ecircle-ag.com/rpc"
      wsdl.namespace = "http://webservices.ecircleag.com/rpcns"
    end
  end
end
