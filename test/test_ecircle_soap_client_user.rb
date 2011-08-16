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

    should "class method for getting group id from either group object or other value" do
      [ ["1", 1], ["2", "2"], ["", ""], ["", nil] ].each do |expval, val|
        assert_equal expval, Ecircle::User.group_id(val), "Failed for #{expval} / #{val}"
      end

      grp = Ecircle::Group.new
      [ ["1", 1], ["2", "2"], ["", ""], ["", nil] ].each do |expval, val|
        grp.id = val
        assert_equal expval, Ecircle::User.group_id(grp), "Failed for #{expval} / #{val}"
      end
    end

    should "return nil when user can't be found" do
      mock_response(in_soap_body do
        <<-SOAP
          <LookupUserByEmailResponse xmlns="">
            <ns1:lookupUserByEmailReturn xsi:nil="true" xmlns:ns1="http://webservices.ecircleag.com/rpcns"/>
          </LookupUserByEmailResponse>
        SOAP
      end)
      assert_equal(nil, Ecircle::User.find_by_email("bogus"))
    end

    should "be able to create via email" do
      user, email, req_obj = Ecircle::User.new, "this@is.the.email.org", Object.new

      user.email = email
      user.title = "-1"

      mock(req_obj).create_user(:userXmlSpec => user.to_xml) { "thisisid" }
      mock(Ecircle).client { req_obj }

      user = Ecircle::User.create_by_email(email)
      assert_equal "thisisid", user.id
      assert_equal email, user.email
    end

    should "return the group ids of a user" do
      id1, id2 = "123", "456"
      mock_response(in_soap_body do
        <<-SOAP
          <FindMembershipsByEmailResponse xmlns="">
            <ns1:findMembershipsByEmailReturn xmlns:ns1="http://webservices.ecircleag.com/rpcns">#{id1}</ns1:findMembershipsByEmailReturn>
            <ns2:findMembershipsByEmailReturn xmlns:ns2="http://webservices.ecircleag.com/rpcns">#{id2}</ns2:findMembershipsByEmailReturn>
          </FindMembershipsByEmailResponse>
        SOAP
      end)
      user = Ecircle::User.new
      user.email = "bla@example.com"
      assert_equal([id1, id2], user.group_ids)
    end

    should "return an array even if there is only one membership" do
      id1 = "123"
      mock_response(in_soap_body do
        <<-SOAP
          <FindMembershipsByEmailResponse xmlns="">
            <ns1:findMembershipsByEmailReturn xmlns:ns1="http://webservices.ecircleag.com/rpcns">#{id1}</ns1:findMembershipsByEmailReturn>
          </FindMembershipsByEmailResponse>
        SOAP
      end)
      user = Ecircle::User.new
      user.email = "bla@example.com"
      assert_equal([id1], user.group_ids)
    end

    should "return an empty array if there is no membership" do
      mock_response(in_soap_body do
        <<-SOAP
          <FindMembershipsByEmailResponse xmlns="">
            <ns1:findMembershipsByEmailReturn xsi:nil="true" xmlns:ns1="http://webservices.ecircleag.com/rpcns"/>
          </FindMembershipsByEmailResponse>
        SOAP
      end)
      user = Ecircle::User.new
      user.email = "bla@example.com"
      assert_equal([], user.group_ids)
    end

    should "return all groups with groups" do
      user = Ecircle::User.new
      mock(user).group_ids { [1] }
      mock(Ecircle::Group).find_by_id(1) { "imagroup" }
      assert_equal(["imagroup"], user.groups)
    end

    should "return all groups with memberships" do
      user = Ecircle::User.new
      mock(user).group_ids { [1,2] }
      mock(Ecircle::Group).find_by_id(1) { "imagroup" }
      mock(Ecircle::Group).find_by_id(2) { "fubar" }
      assert_equal(["imagroup", "fubar"], user.memberships)
    end

    should "return the inclusion into a group by id or group" do
      user = Ecircle::User.new
      mock(user).group_ids.any_number_of_times { ["1", "42", "64"] }
      assert user.in_group?("42")
      assert !user.in_group?("43")
      grp = Ecircle::Group.new
      grp.id = "1"
      assert user.in_group?(grp)
      grp.id = "0"
      assert !user.in_group?(grp)
    end

    should "be able to unsubscribe from a group by using the group id" do
      user, email, req_obj = Ecircle::User.new, "this@is.the.email.org", Object.new

      user.email = email
      group_id = 123456

      mock(req_obj).unsubscribe_member_by_email(
        :groupId     => "123456",
        :email        => email,
        :sendMessage => false
      ) { true }
      mock(Ecircle).client { req_obj }

      assert user.leave_group(group_id)
    end

    should "be able to unsubscribe from a group by using a group object" do
      user, email, req_obj = Ecircle::User.new, "this@is.the.email.org", Object.new

      user.email = email

      group = Ecircle::Group.new
      group.id = "123456"

      mock(req_obj).unsubscribe_member_by_email(
        :groupId => "123456",
        :email   => email,
        :sendMessage => false
      ) { true }
      mock(Ecircle).client { req_obj }

      assert user.leave_group(group)
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
