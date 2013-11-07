module Rseed
  class Attribute
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
      unless options[:match]
        return true if options[:header] and match_name == options[:header]
        return match_name.to_s == self.name.to_s
      end
      re = Regexp.new(options[:match])
      !re.match(match_name).nil?
    end

    def deserialize values
      return nil if values[self.name].nil?
      value = values[self.name]

      if options[:model] && options[:model_attribute]
        # The attribute is a model, we look up the model via the specified attribute
        model_name = options[:model] == true ? self.name : options[:model]
        klass = model_name.to_s.classify.constantize
        model_match = options[:model_match] || :first
        value = klass.where(options[:model_attribute] => value).send(model_match.to_s)
      elsif options[:type]
        # Check for a deserialize function for the type
        dsf = "deserialize_#{options[:type].to_s}"
        if self.respond_to? dsf
          value = self.send(dsf, value)
        end
      end
      value
    end
  end
end
