module Ecircle
  class Group < Ecircle::Base
    class << self
      def find_all_by_name(group_name)
        ary = Ecircle.client.lookup_groups :lookupParams => { :groupName => group_name }
        ary.is_a?(Array) ? ary.collect { |a| Ecircle::Group.new(a) } : []
      end

      def find_by_name(group_name)
        hsh = Ecircle.client.lookup_groups :lookupParams => { :groupName => group_name }
        hsh.is_a?(Hash) ? Group.new(hsh) : raise("Group name #{group_name} not unique")
      end

      def all
        find_all_by_name("")
      end

      def find_by_id(idstr)
        ## TODO there must be a better way of doing this?!
        ## TODO but there isn't a lookupGroupById in the wsdl specification.
        all.reject { |a| a.id != idstr }.first
      end
    end

    def initialize(hsh = nil)
      super()
      @all_fields = hsh || {}
      @id = self[:id]
    end

    # Make a user a member of a group. Can be called multiple times for the same
    # user, eCircle checks for duplicates based on the email or whatever.
    # Returns a member id which then can be used to create a new member.
    def add_member(user, send_invite = false, send_message = false)
      member_id = Ecircle.client.
        create_member(:userId  => user.id,     :groupId     => @id,
                      :invite  => send_invite, :sendMessage => send_message)
      Ecircle::Member.find_by_id(member_id)
    end

    # clone this group at eCircle. For example,
    #     Ecircle::Group.
    #       find_by_name("fubar").
    #       clone( "snafu", "snafu@cmXX.ecircle-ag.com", false )
    def clone(with_name, with_email, keep_owner = true)
      Ecircle.client.
        clone_group(:templateGroupId => @id, :newGroupEmail => with_email,
                    :newGroupName => with_name, :keepOwner => keep_owner)
    end

    def delete
      Ecircle.client.delete_group :groupId => @id
    end

    def to_xml
      # prefer to use u.send(...) but that creates a new xml element called 'send'!
      # hence this is using instance_eval with a string.
      Savon::SOAP::XML.new.xml do |x|
        x.group(:id => @id) do |u|
          u.name(@id)
        end
      end
    end
  end
end
