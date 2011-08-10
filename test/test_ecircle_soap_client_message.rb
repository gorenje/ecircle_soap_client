require File.dirname(__FILE__)+'/helper'
require 'ostruct'

class TestEcircleSoapClientMessage < Test::Unit::TestCase

  def setup
    config_soap_client
  end

  context "Ecircle::Message" do
    should "have all class method" do
      mock(Ecircle::Message).find_all_by_group_name("") { "hi there" }
      assert_equal "hi there", Ecircle::Message.all
    end

    should "find_all_by_group_name - empty array if returned value is no array" do
      mock_ecircle_client do |client|
        client.lookup_messages(:lookupParams => { :groupName => "group name" }) { "ban" }
        assert_equal [], Ecircle::Message.find_all_by_group_name("group name")
      end
    end

    should "find_all_by_group_name - empty array if empty" do
      mock_ecircle_client do |client|
        client.lookup_messages(:lookupParams => { :groupName => "group name" }) { [] }
        assert_equal [], Ecircle::Message.find_all_by_group_name("group name")
      end
    end

    should "find_all_by_group_name - generate messages objects if array" do
      mock_ecircle_client do |client|
        client.lookup_messages(:lookupParams => { :groupName => "group name" }) do
          [{ :id => :one}, { :id => :two}, { :id => :three}]
        end

        result = Ecircle::Message.find_all_by_group_name("group name")
        assert_equal 3, result.count
        assert_equal :one, result.first.id
        assert_equal :two, result[1].id
        assert_equal :three, result.last.id
      end
    end

    should "do a delete" do
      mock_ecircle_client do |client|
        msg = Ecircle::Message.new(:id => "fubar")
        client.delete_message(:messageId => "fubar") { "this is not returned" }
        assert_equal true, msg.delete
      end
    end

    should "delete: capture permission denied fault and return false" do
      mock_ecircle_client do |client|
        msg = Ecircle::Message.new(:id => "fubar")
        client.delete_message(:messageId => "fubar") do
          raise Ecircle::Client::PermissionDenied.new("fubar")
        end
        assert_equal false, msg.delete
      end
    end

    should "delete: propagate other exceptions up" do
      mock_ecircle_client do |client|
        msg = Ecircle::Message.new(:id => "fubar")
        client.delete_message(:messageId => "fubar") do
          raise _soap_fault("Some other unknonwn exception")
        end

        assert_raises Savon::SOAP::Fault do
          msg.delete
        end
      end
    end

    should "return a group object if group_id defined" do
      msg = Ecircle::Message.new(:group_id => "fubar")
      mock(Ecircle::Group).find_by_id("fubar") { "hi there" }
      assert_equal "hi there", msg.group
    end

    should "nil if group_id is set to nil" do
      msg = Ecircle::Message.new(:group_id => nil)
      mock(Ecircle::Group).find_by_id.times(0)
      assert_equal nil, msg.group
    end

    should "nil if group_id not set" do
      msg = Ecircle::Message.new(:id => "fubar")
      mock(Ecircle::Group).find_by_id.times(0)
      assert_equal nil, msg.group
    end

    context "send_to_user" do
      should "raise exception if unknown type" do
        msg = Ecircle::Message.new(:type => "fubar")
        assert_raises Ecircle::Message::MessageTypeUnknown do
          msg.send_to_user nil
        end
      end

      should "use single message if no parameters" do
        mock_ecircle_client do |client|
          msg     = Ecircle::Message.new(:type => 'single', :id => "fubar")
          user    = Ecircle::User.new
          user.id = "snafu"

          client.send_single_message_to_user(:singleMessageId => "fubar",
                                             :userId => user.id)
          result = msg.send_to_user user
          assert_equal true, result.first
          assert_equal nil, result.last
        end
      end

      should "return false and the result if result != nil" do
        mock_ecircle_client do |client|
          msg     = Ecircle::Message.new(:type => 'single', :id => "fubar")
          user    = Ecircle::User.new
          user.id = "snafu"

          client.send_single_message_to_user(:singleMessageId => "fubar",
                                             :userId => user.id) { "result not nil" }
          result = msg.send_to_user user
          assert_equal false, result.first
          assert_equal "result not nil", result.last
        end
      end

      should "use parameterized if there are paramters" do
        mock_ecircle_client do |client|
          msg     = Ecircle::Message.new(:type => 'single', :id => "fubar")
          user    = Ecircle::User.new
          user.id = "snafu"
          parameters = {
            :one => :two,
            :three => :four
          }
          client.
            send_parametrized_single_message_to_user(:singleMessageId => "fubar",
                                                     :userId          => user.id,
                                                     :names           => parameters.keys,
                                                     :values          => parameters.values)
          result = msg.send_to_user user, parameters
          assert_equal true, result.first
          assert_equal nil, result.last
        end
      end

      should "throw exception if type is normal but group id does not exist" do
        msg     = Ecircle::Message.new(:type => 'normal', :id => "fubar")
        user    = Ecircle::User.new
        user.id = "snafu"
        assert_raises Ecircle::Message::MessageGroupNotDefined do
          msg.send_to_user user
        end
      end

      should "use group message if normal and group id is defined" do
        mock_ecircle_client do |client|
          msg     = Ecircle::Message.new(:type => 'normal', :group_id => "groupid",
                                         :id => "fubar")
          user    = Ecircle::User.new
          user.id = "snafu"

          client.send_group_message_to_user(:userId    => user.id, :messageId => "fubar",
                                            :groupid   => "groupid")
          result = msg.send_to_user user
          assert_equal true, result.first
          assert_equal nil, result.last
        end
      end
    end
  end
end
