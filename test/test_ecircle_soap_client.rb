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

  context "Ecircle::Configuration" do
    should "have a use_priority configuration option" do
      assert_equal false, Ecircle.configure.use_priority
      Ecircle.configure.use_priority = true
      assert Ecircle.configure.use_priority
      Ecircle.configure.use_priority = false
    end
  end

  context "Ecircle::Client.attempt" do
    setup do
      @yield_count = 0
    end

    should "yield once if all goes well" do
      assert_difference "@yield_count", 1 do
        Ecircle::Client.attempt do
          @yield_count += 1
        end
      end
    end

    should "raise exception if anything other than is raised" do
      assert_difference "@yield_count", 1 do
        assert_raises RuntimeError do
          Ecircle::Client.attempt do
            @yield_count += 1
            raise RuntimeError, "fubar"
          end
        end
      end
    end

    should "default should be 2 retries" do
      # 3 because the '+= 1' happens before the exception is thrown.
      assert_difference "@yield_count", 3 do
        assert_raises Ecircle::Client::NotLoggedIn do
          Ecircle::Client.attempt do
            @yield_count += 1
            raise Ecircle::Client::NotLoggedIn.new
          end
        end
      end
    end

    should "should retry on NoMethodError but only for findMembershipByEmail" do
      # 3 because the '+= 1' happens before the exception is thrown.
      assert_difference "@yield_count", 1 do
        assert_raises NoMethodError do
          Ecircle::Client.attempt do
            @yield_count += 1
            raise NoMethodError, "funar"
          end
        end
      end

      assert_difference "@yield_count", 3 do
        assert_raises NoMethodError do
          Ecircle::Client.attempt do
            @yield_count += 1
            raise NoMethodError, "No such operation 'FindMembershipsByEmail'"
          end
        end
      end

      assert_difference "@yield_count", 11 do
        assert_raises NoMethodError do
          Ecircle::Client.attempt(10) do
            @yield_count += 1
            raise NoMethodError, "No such operation 'FindMembershipsByEmail'"
          end
        end
      end
    end

    should "retry if one of two errors is thrown - propogate error on final retry" do
      clnobj = Object.new
      mock(clnobj).logon.times(2) { "" }
      mock(Ecircle).client.any_number_of_times { clnobj }

      assert_difference "@yield_count", 6 do
        assert_raises Ecircle::Client::PermissionDenied do
          Ecircle::Client.attempt(retries = 5) do
            @yield_count += 1
            raise Ecircle::Client::NotLoggedIn.new, "fubar" if @yield_count % 2 == 1
            raise Ecircle::Client::PermissionDenied.new , "fubar" if @yield_count % 2 == 0
          end
        end
      end
    end

    should "stop retries if no exception is raised - notloggedin" do
      assert_difference "@yield_count", 5 do
        Ecircle::Client.attempt(retries = 5) do
          @yield_count += 1
          raise Ecircle::Client::NotLoggedIn.new, "fubar" if @yield_count < 5
        end
      end
    end

    should "stop retries if no exception is raised - permission denied" do
      clnobj = Object.new
      mock(clnobj).logon.times(4) { "" }
      mock(Ecircle).client.any_number_of_times { clnobj }

      assert_difference "@yield_count", 5 do
        Ecircle::Client.attempt(retries = 5) do
          @yield_count += 1
          raise Ecircle::Client::PermissionDenied.new, "fubar" if @yield_count < 5
        end
      end
    end

    should "exit immediately if the logon method raises exception" do
      clnobj = Object.new
      mock(clnobj).logon do
        raise Ecircle::Client::PermissionDenied.new, "came from login"
      end
      mock(Ecircle).client.any_number_of_times { clnobj }

      exp = nil
      assert_difference "@yield_count", 1 do
        exp = assert_raises Ecircle::Client::PermissionDenied do
          Ecircle::Client.attempt(retries = 5) do
            @yield_count += 1
            raise Ecircle::Client::PermissionDenied.new, "fubar" if @yield_count < 5
          end
        end
      end
      assert_equal "came from login", exp.message
    end

    should "don't call logon when not loggedin exception is raised" do
      mock(Ecircle).client.times(0)

      assert_difference "@yield_count", 3 do
        Ecircle::Client.attempt(retries = 10) do
          @yield_count += 1
          raise Ecircle::Client::NotLoggedIn.new, "fubar" if @yield_count < 3
        end
      end
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

    should "be able to handle various exceptions" do
      client = Ecircle::Client.new

      assert_raises Savon::SOAP::Fault do
        client.send( :handle_savon_fault, _soap_fault("Unknown exception message"),
                     :for_method => 'fubar')
      end

      assert_raises RuntimeError do
        client.send( :handle_savon_fault, RuntimeError.new("hello world"),
                     :for_method => 'fubar')
      end

      begin
        client.send( :handle_savon_fault, _soap_fault("No such operation"),
                     :for_method => 'fubar')
        assert false, "should not get here."
      rescue NoMethodError => e
        assert_equal "fubar (by way of (client) No such operation)", e.message
      end

      begin
        client.send( :handle_savon_fault, _soap_fault("No such operation"))
        assert false, "should not get here."
      rescue NoMethodError => e
        assert_equal "UNKNOWN (by way of (client) No such operation)", e.message
      end

      assert_raises Ecircle::Client::NotLoggedIn do
        client.send( :handle_savon_fault, _soap_fault("Not authenticated"))
      end
      assert_raises Ecircle::Client::NotLoggedIn do
        client.send( :handle_savon_fault, _soap_fault("LoginException"))
      end

      assert_raises Ecircle::Client::PermissionDenied do
        client.send( :handle_savon_fault, _soap_fault("Authorisation failure"))
      end
      assert_raises Ecircle::Client::PermissionDenied do
        client.send( :handle_savon_fault, _soap_fault("Permission Problem"))
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

    context "parsing results" do

      should "return nil for responses without content except attributes" do
        mock_response(in_soap_body do
          <<-SOAP
            <FoobarResponse xmlns="">
              <ns1:FoobarReturn xsi:nil="true" xmlns:ns1="http://webservices.ecircleag.com/rpcns"/>
            </FoobarResponse>
          SOAP
        end)
        assert_equal(nil, Ecircle.client.foobar)
      end

      should "return nil for responses without fitting content" do
        mock_response(in_soap_body do
          <<-SOAP
            <FoobarResponse xmlns=""/>
          SOAP
        end)
        assert_equal(nil, Ecircle.client.foobar)
      end

      [true, false].each do |boolean|
        should "return #{boolean} for return value of #{boolean}" do
          mock_response(in_soap_body do
            <<-SOAP
              <FoobarResponse xmlns="">
                <ns1:FoobarReturn xsi:nil="true" xmlns:ns1="http://webservices.ecircleag.com/rpcns">
                  #{boolean}
                </ns1:FoobarReturn>
              </FoobarResponse>
            SOAP
          end)
          assert_equal(boolean, Ecircle.client.foobar)
        end
      end

      should "return XML for responses with other content" do
        mock_response(in_soap_body do
          <<-SOAP
            <FoobarResponse xmlns="">
              <ns1:FoobarReturn xsi:nil="true" xmlns:ns1="http://webservices.ecircleag.com/rpcns">
                Snafu
              </ns1:FoobarReturn>
            </FoobarResponse>
          SOAP
        end)
        assert_equal("Snafu", Ecircle.client.foobar.strip)
      end
    end
  end
end
