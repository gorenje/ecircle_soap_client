require 'rubygems'
require 'bundler'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'test/unit'
require 'shoulda'
require 'yaml'
require 'rr'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'ecircle_soap_client'

class Test::Unit::TestCase
  include RR::Adapters::TestUnit

  # ensure we don't end up with duplication in the test naming and shoulda then
  # ignores these tests. only an issue with shoulda.
  def self.method_added(name)
    @@_method_name_store_ ||= {}
    (@@_method_name_store_[self] ||= []).tap do |ary|
      raise RuntimeError, "\n !! Duplicate test: #{name} on #{self}" if ary.include?(name)
      ary << name
    end
  end

  def use_priority_to_send_mail(&block)
    Ecircle.configure.use_priority = true
    yield
  ensure
    Ecircle.configure.use_priority = false
  end

  def _soap_fault(msg)
    os = OpenStruct.new
    os.body = Savon::SOAP::XML.new.xml do |x|
      x.envelope do |e|
        e.body do |b|
          b.Fault do |f|
            f.faultcode("client")
            f.faultstring(msg)
          end
        end
      end
    end
    Savon::SOAP::Fault.new(os)
  end

  def mock_ecircle_client(create_client_object = false)
    if create_client_object
      client, req_obj = Ecircle::Client.new, Object.new
      mock(client).client { req_obj }
      # don't mock client since this will be used directly.
      yield(client, mock(req_obj))
    else
      req_object = Object.new
      mock(Ecircle).client { req_object }
      yield(mock(req_object))
    end
  end

  def in_soap_body
    <<-SOAP
     <?xml version="1.0" encoding="UTF-8"?>
      <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
        <soapenv:Body>
         #{yield}
        </soapenv:Body>
      </soapenv:Envelope>
    SOAP
  end

  def mock_response(resp)
    mock_ecircle_client(true) do |client, savon_client|
      mock(Ecircle).client { client }
      mock(client).logon { nil }
      savon_client.request.with_any_args do
        Savon::SOAP::Response.new(HTTPI::Response.new(200, {}, resp))
      end
    end
  end

  def config_soap_client
    # keep login details separate from gem.
    settings = begin
                 YAML::load_file(File.join(File.dirname(__FILE__), '.login.yml'))
               rescue
                 puts "NO test/.login.yml --> copy the sample across to test"
                 exit 1
               end

    Ecircle.configure do |config|
      config.user     = settings["user"]
      config.realm    = settings["realm"]
      config.password = settings["password"]
    end
  end

  def assert_difference(expression, difference = 1, message = nil, &block)
    b = block.send(:binding)
    exps = Array.wrap(expression)
    before = exps.map { |e| eval(e, b) }

    yield

    exps.each_with_index do |e, i|
      error = "#{e.inspect} didn't change by #{difference}"
      error = "#{message}.\n#{error}" if message
      assert_equal(before[i] + difference, eval(e, b), error)
    end
  end
end

# Rails extension required for assert_difference (another rails extension)
class Array
  def self.wrap(object)
    if object.nil?
      []
    elsif object.respond_to?(:to_ary)
      object.to_ary
    else
      [object]
    end
  end
end
