require 'nokogiri'
require 'sax-machine/ns_stack'

module SAXMachine
  class SAXHandler < Nokogiri::XML::SAX::Document
    attr_reader :object

    def initialize(object, nsstack=nil)
      @object = object
      @nsstack = nsstack || NSStack.new
    end

    def characters(string)
      if parsing_collection?
        @collection_handler.characters(string)
      elsif @element_config
        if !@value || @value == EMPTY_STRING
          @value = string
        else
          @value << string
        end
      end
    end

    def cdata_block(string)
      characters(string)
    end

    def start_element(name, attrs = nil)
      @name   = name
      @attrs  = (attrs || []).map do |k, v|
        # Do we actually need to decode the attribute key or just the value?
        [SAXHandler.decode_xml(k), SAXHandler.decode_xml(v)]
      end
      @nsstack  = NSStack.new(@nsstack, @attrs)

      if parsing_collection?
        @collection_handler.start_element(@name, @attrs)
      elsif @collection_config = sax_config.collection_config(@name, @nsstack)
        @collection_handler = @collection_config.handler(@nsstack)
        if @object.class != @collection_handler.object.class
          @collection_handler.start_element(@name, @attrs)
        end
      elsif (element_configs = sax_config.element_configs_for_attribute(@name, @attrs)).any?
        parse_element_attributes(element_configs)
        set_element_config_for_element_value
      else
        set_element_config_for_element_value
      end
    end

    def end_element(name)
      if parsing_collection? && @collection_config.name == name.split(COLON, 2).last
        @collection_handler.end_element(name)
        @object.send(@collection_config.accessor) << @collection_handler.object
        reset_current_collection
      elsif parsing_collection?
        @collection_handler.end_element(name)
      elsif characters_captured? && !@element_config.has_value?
        @object.send(@element_config.setter, @value)
      end

      reset_current_tag
      @nsstack = @nsstack.pop
    end

    def characters_captured?
      !@value.nil? && !@value.empty?
    end

    def parsing_collection?
      !@collection_handler.nil?
    end

    def parse_element_attributes(element_configs)
      element_configs.each do |ec|
        @object.send(ec.setter, ec.value_from_attrs(@attrs))
      end
      @element_config = nil
    end

    def set_element_config_for_element_value
      @value = EMPTY_STRING
      @element_config = sax_config.element_config_for_tag(@name, @attrs, @nsstack)
    end

    def reset_current_collection
      @collection_handler = nil
      @collection_config  = nil
    end

    def reset_current_tag
      @name   = nil
      @attrs  = nil
      @value  = nil
      @element_config = nil
    end

    def sax_config
      @object.class.sax_config
    end

    ##
    # Decodes XML special characters.
    def self.decode_xml(str)
      return str.map(&method(:decode_xml)) if str.kind_of?(Array)

      # entities = {
      #         '#38'   => '&amp;',
      #         '#13'   => "\r",
      #       }
      #       entities.keys.inject(str) { |string, key|
      #         string.gsub(/&#{key};/, entities[key])
      #       }
      CGI.unescapeHTML(str)
    end
  end
end
