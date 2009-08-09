require "nokogiri"

module SAXMachine
  
  def self.included(base)
    base.extend ClassMethods
  end
  
  def parse(xml_text)
    unless @parser
      sax_handler = SAXHandler.new(self)
      @parser = Nokogiri::XML::SAX::PushParser.new(sax_handler)
    end
    @parser << xml_text
    self
  end

  def parse_finish
    if @parser
      @parser.finish
    end
    self
  end
  
  module ClassMethods

    def parse(xml_text)
      # It might be cleaner to aditionally call parse_finish here, but
      # then Nokogiri/libxml2 barfs on incomplete documents. Desired
      # behaviour?
      new.parse(xml_text)
    end
    
    def element(name, options = {})
      options[:as] ||= name
      sax_config.add_top_level_element(name, options)
      
      # we only want to insert the getter and setter if they haven't defined it from elsewhere.
      # this is how we allow custom parsing behavior. So you could define the setter
      # and have it parse the string into a date or whatever.
      attr_reader options[:as] unless instance_methods.include?(options[:as].to_s)
      attr_writer_once options[:as] unless instance_methods.include?("#{options[:as]}=")
    end

    def columns
      r = []
      sax_config.top_level_elements.each do |name, ecs|
        r += ecs
      end
      r
    end

    def column(sym)
      (sax_config.top_level_elements[sym.to_s] || []).first
    end

    def data_class(sym)
      column(sym).data_class
    end

    def required?(sym)
      column(sym).required?
    end

    def column_names
      columns.map{|e| e.column}
    end
    
    def elements(name, options = {})
      options[:as] ||= name
      if options[:class] || options[:events]
        sax_config.add_collection_element(name, options)
      else
        class_eval <<-SRC
          def add_#{options[:as]}(value)
            #{options[:as]} << value
          end
        SRC
        sax_config.add_top_level_element(name, options.merge(:collection => true))
      end
      
      if !instance_methods.include?(options[:as].to_s)
      class_eval <<-SRC
          def #{options[:as]}
            @#{options[:as]} ||= []
          end
        SRC
      end
      
      attr_writer options[:as] unless instance_methods.include?("#{options[:as]}=")
    end
    
    def sax_config
      @sax_config ||= SAXConfig.new
    end

    def attr_writer_once(attr)
      class_eval <<-SRC
          def #{attr}=(val)
            @#{attr} ||= val
          end
        SRC
    end
  end
  
end
