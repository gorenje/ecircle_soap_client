module Ecircle
  class Client
    attr_reader :session_token

    LoginFailed = Class.new(RuntimeError)
    NotLoggedIn = Class.new(RuntimeError)

    # Savon::SOAP::Fault: (ns1:Client) No such operation
    # Savon::SOAP::Fault: (soapenv:Server.userException) com.ecircleag.webservices.EcMException: Not authenticated
    # Savon::SOAP::Fault: (soapenv:Server.userException) com.ecircleag.webservices.EcMException: Error: com.domeus.filter.web.IllegalParameterException: Not a valid email address.: pemail
    def initialize
      @session_token = nil
    end

    # This is the magic. All we do here is take the method name, camelcase it and
    # then pass it to eCircle. It is assumed that the args array contains a hash
    # as the first element. This then contains the arguments for the call. E.g.:
    #    Ecircle.client.lookup_user_by_email :email => "willy@wonka.net"
    # This will do a number of things:
    #   1. login if session token is undefined
    #   2. set the session parameter along with the email argument
    #   3. check for specific eCircle exceptions and attempt to handle them.
    def method_missing(method, *args, &block)
      logon if @session_token.nil?

      method_name, body = method.to_s.camelcase, args.first || {}
      body[:session] = @session_token

      response = begin
                   client.request(method_name) { soap.body = body }
                 rescue Savon::SOAP::Fault => e
                   case e.message
                   when /No such operation/ then
                     raise NoMethodError, "#{method} (by way of #{e.message})"
                   when /Not authenticated/ then
                     @session_token = nil # automagically login with the next call.
                     raise NotLoggedIn, "#{e.message}"
                   else
                     raise e
                   end
                 end

      data = response.
        body["#{method}_response".to_sym]["#{method}_return".to_sym]

      case data
        when /^[<]user/ then Ecircle::User.new(data)
        when /^[<]member/ then Ecircle::Member.new(data)
      else
        data
      end
    end

    # Generate a Savon::Client to use for making requests. The configuration for the
    # client is taken from the configure object.
    def client
      @client ||= Savon::Client.new do
        wsdl.document  = Ecircle.configure.wsdl.document
        wsdl.endpoint  = Ecircle.configure.wsdl.endpoint
        wsdl.namespace = Ecircle.configure.wsdl.namespace
      end
    end

    # Send logon request and store the session token if successful.
    # The session token is then passed into each subsequent request to
    # eCircle.
    def logon
      @session_token = (client.request :logon do
        soap.body = {
          :user   => Ecircle.configure.user,
          :realm  => Ecircle.configure.realm,
          :passwd => Ecircle.configure.password
        }
      end).body[:logon_response][:logon_return].to_s
    rescue Savon::SOAP::Fault => e
      @session_token = nil
      raise LoginFailed, "Msg: #{e.message}"
    end

    # Invalid the session token and set it to nil.
    # The session token automagically expires after 10 minutes of inactivity, so
    # you might have to logout if methods are with NotLoggedIn
    def logout
      client.request :logout do
        soap.body = {
          :session => @session_token
        }
      end
    ensure
      @session_token = nil
    end

  end
end
