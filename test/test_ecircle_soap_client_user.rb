require File.dirname(__FILE__)+'/helper'
require 'ostruct'

class TestEcircleSoapClientUser < Test::Unit::TestCase

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
  end

  context "Ecircle::User" do
    should "be able to create via email" do
      user, email, req_obj = Ecircle::User.new, "this@is.the.email.org", Object.new

      user.email = email
      user.title = "-1"

      mock(req_obj).create_user(:userXmlSpec => user.to_xml) { "thisisid" }
      mock(Ecircle).client { req_obj }

      u = Ecircle::User.create_by_email(email)
      assert_equal "thisisid", u.id
      assert_equal email, u.email
    end

    should "support namedattr's for defining custom values" do
      attrs = {
          "fubar" => "value",
          "attr2" => "bill's",
          "attr3" => "miracle",
          "attr4" => "adventure",
          "attr5" => "inwonderland",
      }

      complex_user_string = Savon::SOAP::XML.new.xml do |x|
        x.user(:id => "4130268167") do |u|
          attrs.each do |key,value|
            x.namedattr({:name => key}, value)
          end
        end
      end

      user = Ecircle::User.new(complex_user_string)
      attrs.each do |key,value|
        assert_equal value, user.named_attrs[key], "FAILED for #{key}"
      end
    end

    should "be able to generate xml from user" do
      user = Ecircle::User.new(@example_user_string)
      assert_equal("<?xml version=\"1.0\" encoding=\"UTF-8\"?><user id=\"4130268167\">"+
                   "<email>bill@microsoft.com</email><title>-1</title><firstname>Bill<"+
                   "/firstname><lastname>Gates</lastname><nickname></nickname><dob_dd>"+
                   "</dob_dd><dob_mm></dob_mm><dob_yyyy></dob_yyyy><countrycode>US</co"+
                   "untrycode><languagecode>en</languagecode><cust_attr_1></cust_attr_"+
                   "1><cust_attr_2></cust_attr_2><cust_attr_3></cust_attr_3><cust_attr"+
                   "_4></cust_attr_4><cust_attr_5></cust_attr_5><cust_attr_6></cust_at"+
                   "tr_6><cust_attr_7></cust_attr_7><cust_attr_8></cust_attr_8><cust_a"+
                   "ttr_9></cust_attr_9></user>", user.to_xml)
    end

    should "be instantiable from xml string" do
      user = Ecircle::User.new(@example_user_string)

      assert_equal "4130268167", user.id
      assert_equal "bill@microsoft.com", user.email
      assert_equal "bill@microsoft.com", user[:email]
      assert_equal "bill@microsoft.com", user["email"]
      assert_equal "US", user[:countrycode]
      assert_equal "en", user[:languagecode]
      9.times do |idx|
        assert_equal "", user["cust_attr_#{idx+1}"], "Failed for cust_attr_#{idx+1}"
      end
    end
  end
end
