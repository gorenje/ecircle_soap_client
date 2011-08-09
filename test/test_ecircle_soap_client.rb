require File.dirname(__FILE__)+'/helper'
require 'ostruct'

class TestEcircleSoapClient < Test::Unit::TestCase

  def setup
    config_soap_client
  end

  context "time helpers" do
    should "extend Time with ecircle_format" do
      assert_equal({ :snafu_yyyy => '1910',
                     :snafu_mm   => '00',
                     :snafu_dd   => '01',
                     :snafu_hh   => '04',
                     :snafu_min  => '03',
                     :snafu_ss   => '09',
                   }, Time.mktime(1910, 1, 1, 4, 3, 9).ecircle_format("snafu"))
    end

    should "extend Date with ecircle_format" do
      assert_equal({ :fubar_yyyy => '1910',
                     :fubar_mm   => '00',
                     :fubar_dd   => '01',
                     :fubar_hh   => '00',
                     :fubar_min  => '00',
                     :fubar_ss   => '00',
                   }, Date.new(1910, 1, 1).ecircle_format("fubar"))
    end
  end

  context "Ecircle::Client" do
    should "logon if not logged in" do
      mock_ecircle_client(true) do |client, req_obj|
        req_obj.request("FuBaR") { raise _soap_fault("No such operation: fu_ba_r") }
        mock(client).logon { nil }

        assert_raises NoMethodError do
          client.method_missing(:fu_ba_r, nil)
        end
      end
    end

    should "throw not logged in exception" do
      mock_ecircle_client(true) do |client, req_obj|
        req_obj.request("FuBaR") { raise _soap_fault("Not authenticated: stupid me") }
        mock(client).logon { nil }

        assert_raises Ecircle::Client::NotLoggedIn do
          client.method_missing(:fu_ba_r, nil)
        end
      end
    end

    should "propagate unknown exception up" do
      mock_ecircle_client(true) do |client, req_obj|
        req_obj.request("FuBaR") { raise _soap_fault("Not a valid email") }
        mock(client).logon { nil }

        assert_raises Savon::SOAP::Fault do
          client.method_missing(:fu_ba_r, nil)
        end
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
end
