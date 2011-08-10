module Ecircle
  class Message < Ecircle::Base

    MessageTypeUnknown = Class.new(RuntimeError)
    MessageGroupNotDefined = Class.new(RuntimeError)

    class << self
      def find_all_by_group_name(group_name)
        ary = Ecircle.client.lookup_messages :lookupParams => { :groupName => group_name }
        ary.is_a?(Array) ? ary.collect { |a| Ecircle::Message.new(a) } : []
      end

      def find_by_id(idstr)
        ## TODO no lookupMessageById, hence this workaround.
        all.reject { |msg| msg.id != idstr }.first
      end

      def all
        find_all_by_group_name("")
      end
    end

    def initialize(hsh)
      super()
      @all_fields = hsh
      @id = self[:id]
    end

    def subject
      self[:subject]
    end

    def group
      # a single message could potentially have no group_id? Either case this
      # should just return nil instead of raising an exception.
      Ecircle::Group.find_by_id(self[:group_id]) if self[:group_id]
    end

    def delete
      Ecircle.client.delete_message :messageId => self.id
      true
    rescue Ecircle::Client::PermissionDenied => e
      false
    end

    # This does one of two things, if the message is of type 'single', then
    # it uses send_single_message_to_user, else if the type is 'normal' then
    # it uses the send_group_message_to_user.
    #
    # If parameters are given and this is a single message, then a parameterized
    # version of the message is sent.
    #
    # Return value is an array with the first value being boolean to indicate
    # success status. The second value is the original result returned by the
    # ecircle API. The thing is, that ecircle will return nil on success, so
    # in that case, we return [true, nil].
    def send_to_user(user, parameters = nil)
      result = case self[:type]

               when /single/
                 if parameters.nil?
                   Ecircle.client.
                     send_single_message_to_user(:singleMessageId => @id,
                                                 :userId => user.id)
                 else
                   paras = { :singleMessageId => @id,
                             :userId          => user.id,
                             :names           => parameters.keys,
                             :values          => parameters.values,
                           }
                   Ecircle.client.send_parametrized_single_message_to_user(paras)
                 end

               when /normal/
                 # raise an exception because this is inconsistent: a group message without
                 # group_id is not possible.
                 raise MessageGroupNotDefined, "MsgId: #{self.id}" unless self[:group_id]

                 Ecircle.client.
                   send_group_message_to_user(:userId    => user.id,
                                              :messageId => @id,
                                              :groupid   => self[:group_id])
               else
                 raise(MessageTypeUnknown, "Type: #{self[:type]} unknown for "+
                       "MsgId: #{self.id}")
               end

      # strangely, if the message sending worked out, then ecircle sends nil, i.e.
      # nothing back. Else we get some sort of strange error or exception.
      result.nil? ? [true, nil] : [false, result]
    end
  end
end
