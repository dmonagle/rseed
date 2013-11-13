module Rseed
  class Converter
    class << self
      attr_accessor :converter_attributes
    end

    attr_writer :logger
    attr_reader :error
    attr_writer :options

    def self.name
      class_name = self.to_s
      m = /^(?<name>.*)Converter$/.match(class_name)
      m ? m[:name] : class_name
    end

    def name
      self.class.name
    end

    def logger
      @logger.nil? ? Rseed.logger : @logger
    end

    def options
      @options ||= {}
      @options
    end

    # Used to define an attribute when creating a converter.
    def self.attribute name, options
      @converter_attributes ||= []
      converter_attributes << Attribute.new(name, options)
    end

    def before_deserialize
      true
    end

    def after_deserialize
    end

    def self.mandatory_attributes
      converter_attributes.reject { |a| a.options[:optional] }
    end

    # Takes the raw values coming out of an adapter and converts them based on the attribute definitions in the
    # converter.
    def deserialize_raw values
      converted_values = HashWithIndifferentAccess.new
      self.class.converter_attributes.each do |attribute|
        converted_values[attribute.name] = attribute.deserialize(values, converter: self)
      end

      deserialize converted_values
    end

    # Dummy convert function
    def deserialize values
      logger.debug values
    end

    # Helpers for converters
    def remove_nil_from values
      values.delete_if { |k, v| v.nil? }
    end

    def remove_blank_from values
      values.delete_if { |k, v| v.to_s.blank? }
    end

    def fail_with_error e
      @error = e
      false
    end
  end
end