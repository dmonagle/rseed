module Rseed
  class Attribute
    include AttributeConverters

    attr_accessor :name
    attr_accessor :options

    def initialize(name, options = {})
      @name = name
      @options = options
    end

    def header
      return options[:header] || name
    end

    def matches? match_name
      #return true if options[:header] and match_name == options[:header]
      match = options[:match] || /^#{Regexp.escape(self.name)}$/i
      re = match.is_a?(Regexp) ? match : Regexp.new(match, true)
      !re.match(match_name).nil?
    end

    def deserialize values, deserialize_options = {}
      return nil if values[self.name].nil?
      value = values[self.name]

      if options[:model_attribute] || options[:model]
        model = options[:model] || true
        model_attribute = options[:model_attribute] || :id
        # The attribute is a model, we look up the model via the specified attribute
        model_name = model == true ? self.name : model
        klass = model_name.is_a?(Class) ? model_name : model_name.to_s.classify.constantize
        model_match = options[:model_match] || :first
        value = klass.where(model_attribute => value).send(model_match.to_s)
      elsif options[:type]
        # Check for a deserialize function for the type
        dsf = "deserialize_#{options[:type].to_s}"
        if deserialize_options[:converter] && deserialize_options[:converter].respond_to?(dsf)
          value = deserialize_options[:converter].send(dsf, value)
        elsif self.respond_to? dsf
          value = self.send(dsf, value)
        end
      end
      value
    end
  end
end
