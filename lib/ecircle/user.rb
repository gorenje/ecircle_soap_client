module Ecircle
  class User
    attr_reader :id, :all_fields

    def initialize(xml_string)
      n = Nokogiri.parse(xml_string)
      @id = n.xpath('user/@id' ).to_s
      @all_fields = Hash[ n.xpath('//user/*').collect do |a|
                            [a.name, a.children.first.to_s]
                          end ]
    end

    def method_missing(method, *args, &block)
      case method.to_s
      when /\[\]=/ then super
      when /(.+)=/
        puts "''#{ $1 }'' = #{args.first}"
        @all_fields[$1.to_s] = args.first
      else
        super
      end
    end

    def [](name)
      @all_fields[name.to_s]
    end

    def email
      self[:email]
    end

    def id=(value)
      @id = value
    end

    def to_xml
      # prefer to use u.send(...) but that creates a new xml element called 'send'!
      # hence this is using instance_eval with a string.
      Savon::SOAP::XML.new.xml do |x|
        x.user(:id => @id) do |u|
          u.email(self.email)
          [:title, :firstname, :lastname, :nickname, :dob_dd,
           :dob_mm, :dob_yyyy,:countrycode,:languagecode].each do |field_name|
            u.instance_eval "#{field_name}('#{self[field_name]}')"
          end
          9.times do |idx|
            field_name = "cust_attr_#{idx+1}"
            u.instance_eval "#{field_name}('#{self[field_name]}')"
          end
        end
      end
    end
  end
end
