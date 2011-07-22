require File.dirname(__FILE__)+'/helper'
require 'ostruct'

class TestEcircleSoapClientMember < Test::Unit::TestCase

  def setup
    config_soap_client

    @example_member_string = Savon::SOAP::XML.new.xml do |x|
      x.member(:id => "4130268167g400123451") do |u|
        u.email("me@you.com")
      end
    end
  end

  context "Ecircle::Member" do
    should "have group id and user id from id" do
      m = Ecircle::Member.new(@example_member_string)
      assert_equal "4130268167", m.user_id
      assert_equal "400123451", m.group_id
    end

    should "be able to get the group for a member" do
      mock(Ecircle::Group).find_by_id("400123451") { "hi there" }
      assert_equal "hi there", Ecircle::Member.new(@example_member_string).group
    end

    should "be able to get the user for a member" do
      mock(Ecircle::User).find_by_id("4130268167") { "hi there" }
      assert_equal "hi there", Ecircle::Member.new(@example_member_string).user
    end

    should "be able delete a member" do
      mock_ecircle_client do |client|
        client.delete_member(:memberId => "4130268167g400123451") { "he there" }
        assert_equal "he there", Ecircle::Member.new(@example_member_string).delete
      end
    end

    should "be able to find a member by id" do
      mock_ecircle_client do |client|
        member_id = "thisisthememnberid"
        client.lookup_member_by_id(:memberid => member_id) { "he there" }
        assert_equal "he there", Ecircle::Member.find_by_id(member_id)
      end
    end
  end
end
