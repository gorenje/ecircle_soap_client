module Ecircle
  class Member < Ecircle::Base
    class << self
      def find_by_id(member_id)
        Ecircle.client.lookup_member_by_id :memberid => member_id
      end
    end

    def initialize(xml_string)
      init_with_xml("member", xml_string)
    end

    def delete
      Ecircle.client.delete_member :memberId => @id
    end

    ## TODO with assume that the member id is the form of "<userid>g<groupid>", hence
    ## TODO split on 'g' should work!
    def user_id  ; @id.split(/g/).first ; end
    def group_id ; @id.split(/g/).last ; end

    def group
      Ecircle::Group.find_by_id(group_id)
    end
    def user
      Ecircle::User.find_by_id(user_id)
    end

  end
end
