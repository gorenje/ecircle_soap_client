module Ecircle
  class User < Ecircle::Base

    class << self
      def create_by_email(email)
        u = User.new
        u.email = email
        ## TODO why must the title be defined
        u.title = "-1"
        u.id = Ecircle.client.create_user :userXmlSpec => u.to_xml
        u
      end

      def find_by_email(email)
        Ecircle.client.lookup_user_by_email :email => email
      end

      def find_by_identifier(idstr)
        Ecircle.client.lookup_user_by_identifier :identifier => idstr
      end

      def find_by_id(idstr)
        Ecircle.client.lookup_user_by_id :userId => idstr
      end
    end

    def initialize(xml_string = nil)
      super()
      initialize_with_xml(xml_string) if xml_string
    end

    def email
      self[:email]
    end

    def delete
      Ecircle.client.delete_user :user_id => @id
    end

    def create_or_update(send_message = false)
      Ecircle.client.
        create_or_update_user_by_email :userXml => to_xml, :sendMessage => send_message
    end

    def save
      Ecircle.client.update_user :userXmlSpec => to_xml
    end

    # Returns the group ids this user is signed up to as an Array of strings.
    def group_ids
      [Ecircle.client.find_memberships_by_email(:email => email)].flatten.compact
    end

    def groups
      group_ids.collect { |grpid| Ecircle::Group.find_by_id(grpid) }
    end
    alias_method :memberships, :groups

    # +group_or_id+ may be a Ecircle::Group
    # object, containing the group's id, or the id directly.
    def in_group?(group_or_id)
      group_ids.include?(Ecircle::User.group_id(group_or_id))
    end

    def join_group(group, send_invite = false, send_message = false)
      group.add_member self, send_invite, send_message
    end

    # Unsubscribe this user from the given group. group may be a Ecircle::Group
    # object, containing the group's id, or the id directly.
    # Always returns true.
    def leave_group(group_or_id, send_message = false)
      Ecircle.client.
        unsubscribe_member_by_email(:groupId     => Ecircle::User.group_id(group_or_id),
                                    :email       => email,
                                    :sendMessage => send_message)
    end

    def to_xml
      obj = self # in instance_eval 'self' will be something else, so create new
                 # reference to te self containing all the data.

      # prefer to use u.send(...) but that creates a new xml element called 'send'!
      # hence this is using instance_eval with a string.
      Savon::SOAP::XML.new.xml do |x|
        x.user(:id => @id) do |u|
          # email is special, so so so special.
          u.email(self.email)

          # base attributes of a user
          [:title, :firstname, :lastname, :nickname, :dob_dd,
           :dob_mm, :dob_yyyy,:countrycode,:languagecode].each do |field_name|
            u.instance_eval "%s(obj[:%s])" % ([field_name]*2)
          end

          # cust_attr_X
          9.times.collect { |idx| "cust_attr_#{idx+1}" }.
            each do |field_name|
            u.instance_eval "%s(obj[:%s])" % ([field_name]*2)
          end

          # named attributes, these are generic and defined by some guy in a suit.
          named_attrs.each do |key,value|
            u.namedattr({:name => key}, value)
          end
        end
      end
    end

    private

    def self.group_id(group_obj_or_id)
      (group_obj_or_id.is_a?(Ecircle::Group) ? group_obj_or_id.id : group_obj_or_id).to_s
    end

    def initialize_with_xml(xml_string)
      init_with_xml("user", xml_string)
    end
  end
end
