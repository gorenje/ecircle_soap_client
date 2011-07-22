require File.dirname(__FILE__)+'/helper'
require 'ostruct'

class TestEcircleSoapClientGroup < Test::Unit::TestCase

  def setup
    config_soap_client

    @example_user_string = Savon::SOAP::XML.new.xml do |x|
      x.user(:id => "4130268167") do |u|
        u.email("bill@microsoft.com")
        u.title("-1")
        u.firstname("Bill")
        u.lastname("Gates")
        u.nickname("")
        u.dob_dd("")
        u.dob_mm("")
        u.dob_yyyy("")
        u.countrycode("US")
        u.languagecode("en")
        9.times do |idx|
          u.instance_eval "cust_attr_#{idx+1}('')"
        end
      end
    end

    @example_member_string = Savon::SOAP::XML.new.xml do |x|
      x.member(:id => "4130268167g400123451") do |u|
        u.email("me@you.com")
      end
    end
  end

  context "Ecircle::Group" do
    should "be tested" do
      assert true
    end
  end
end
