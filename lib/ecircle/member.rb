module Ecircle
  class Member
    attr_reader :id, :all_fields

    def initialize(xml_string)
      n = Nokogiri.parse(xml_string)
      @id = n.xpath('member/@id' ).to_s
      @all_fields = Hash[ n.xpath('//member/*').collect do |a|
                            [a.name, a.children.first.to_s]
                          end ]
    end

    def [](name)
      @all_fields[name.to_s]
    end
  end
end
