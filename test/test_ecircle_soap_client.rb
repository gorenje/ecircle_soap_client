require File.dirname(__FILE__)+'/helper'
require 'ostruct'

class TestEcircleSoapClient < Test::Unit::TestCase
  def setup
    config_client
    @example_user_string = Savon::SOAP::XML.new.xml do |x|
      x.user(:id => "4130268167") do |u|
        u.email("mathias@teameurope.net")
        u.title("-1")
        u.firstname("Mathias")
        u.lastname("Kutzner")
        u.nickname("")
        u.dob_dd("")
        u.dob_mm("")
        u.dob_yyyy("")
        u.countrycode("DE")
        u.languagecode("de")
        9.times do |idx|
          u.instance_eval "cust_attr_#{idx+1}('')"
        end
      end
    end
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

  context "Ecircle::Client" do
    should "logon if not logged in" do
      client, req_obj = Ecircle::Client.new, Object.new

      mock(req_obj).request("FuBaR") do
        raise _soap_fault("No such operation: fu_ba_r")
      end
      mock(client).logon { nil }
      mock(client).client { req_obj }
      assert_raises NoMethodError do
        client.method_missing(:fu_ba_r, nil)
      end
    end

    should "throw not logged in exception" do
      client, req_obj = Ecircle::Client.new, Object.new

      mock(req_obj).request("FuBaR") do
        raise _soap_fault("Not authenticated: stupid me")
      end
      mock(client).logon { nil }
      mock(client).client { req_obj }
      assert_raises Ecircle::Client::NotLoggedIn do
        client.method_missing(:fu_ba_r, nil)
      end
    end

    should "propagate unknown exception up" do
      client, req_obj = Ecircle::Client.new, Object.new

      mock(req_obj).request("FuBaR") do
        raise _soap_fault("Not a valid email")
      end
      mock(client).logon { nil }
      mock(client).client { req_obj }
      assert_raises Savon::SOAP::Fault do
        client.method_missing(:fu_ba_r, nil)
      end
    end

    should "not logon if already logged in" do
      client, req_obj = Ecircle::Client.new, Object.new

      mock(req_obj).request(:logon) do
        OpenStruct.
          new({:body => { :logon_response => { :logon_return => "somesessiontoken" }}})
      end
      mock(req_obj).request("Logon") do
        OpenStruct.
          new({:body => { :logon_response => { :logon_return => "somesessiontoken" }}})
      end
      mock(client).client.times(2) { req_obj }

      client.logon
      assert_equal "somesessiontoken", client.session_token

      # now the session token is set, the logon method should not be called again.
      mock(client).logon.times(0)
      assert_equal "somesessiontoken", client.method_missing(:logon, nil)
    end
  end

  context "Ecircle::User" do
    should "be instantiable from xml string" do
      user = Ecircle::User.new(@example_user_string)

      assert_equal "4130268167", user.id
      assert_equal "mathias@teameurope.net", user.email
      assert_equal "mathias@teameurope.net", user[:email]
      assert_equal "mathias@teameurope.net", user["email"]
      assert_equal "DE", user[:countrycode]
      assert_equal "de", user[:languagecode]
      9.times do |idx|
        assert_equal "", user["cust_attr_#{idx+1}"], "Failed for cust_attr_#{idx+1}"
      end
    end
  end
end
