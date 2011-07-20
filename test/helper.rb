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

  def config_client
    # keep login details separate from this gem.
    settings = YAML::load_file(File.join(File.dirname(__FILE__), '.login.yml'))
    Ecircle.configure do |config|
      config.user     = settings["user"]
      config.realm    = settings["realm"]
      config.password = settings["password"]
    end
  end
end
