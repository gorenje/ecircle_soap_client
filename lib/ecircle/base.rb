module Ecircle
  class Base
    attr_reader :id, :all_fields, :named_attrs

    def id=(value)
      @id = value
    end

    def [](name)
      @all_fields[name.to_sym]
    end

    def initialize
      @id, @all_fields, @named_attrs = "", {}, {}
    end

    def init_with_xml(element_name, xml_string)
      n = Nokogiri.parse(xml_string)
      @id = n.xpath("#{element_name}/@id" ).to_s
      @all_fields = Hash[ n.xpath("//#{element_name}/*").collect do |a|
                            [a.name.to_sym, a.children.first.to_s]
                          end ]
      @named_attrs = Hash[ n.xpath("#{element_name}/namedattr").collect do |a|
                             [a.attributes["name"].value,
                              a.children.empty? ? "" : a.children.first.to_s]
                           end ]
    end

    # Handle all assignments, everything else is propagated to super.
    def method_missing(method, *args, &block)
      case method.to_s
      when /\[\]=/ then super
      when /(.+)=/
        @all_fields[$1.to_sym] = args.first
      else
        super
      end
    end
  end
end
