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
end
