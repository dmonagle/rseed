module Rseed
  module AttributeConverters
    def deserialize_string(value)
      # If the string represents a number with .0 on the end (something that comes from Roo excel, then remove it)
      # this is a big problem with phone numbers.
      value.gsub!(/\.0+$/, '') if (value.to_i == value.to_f) if /^\s*[\d]+(\.0+){0,1}\s*$/.match(value.to_s)
      return nil if value.to_s.blank? || value.to_s.nil?
      value.to_s
    end

    def deserialize_clean_string(value)
      value = value.to_i if (value.to_i == value.to_f) if /^\s*[\d]+(\.0+){0,1}\s*$/.match(value.to_s)
      value = value.gsub(/[^A-Za-z0-9 \.,\?'""!@#\$%\^&\*\(\)-_=\+;:<>\/\\\|\}\{\[\]`~]/, '').strip if value.is_a?(String)
      return nil if value.to_s.blank? || value.to_s.nil?
      value.to_s
    end

    def deserialize_boolean value
      /^y|t/.match(value.strip.downcase) ? true : false
    end

    def deserialize_decimal value
      BigDecimal(value)
    end

    def deserialize_date s
      return nil if (s.nil? || s.blank?)
      return Date.strptime(s, "%d/%m/%y") if /^[0-9]{1,2}\/[0-9]{1,2}\/[0-9]{2}$/.match(s)
      return DateTime.new(1899, 12, 30) + s.to_f if s.to_f unless s !~ /^\s*[+-]?((\d+_?)*\d+(\.(\d+_?)*\d+)?|\.(\d+_?)*\d+)(\s*|([eE][+-]?(\d+_?)*\d+)\s*)$/
      begin
        result = Date.parse(s)
      rescue
        Rseed.logger.error "Could not parse date ".red + "'#{s}'"
      end

      return result
    end

    def deserialize_datetime s
      begin
        result = Time.zone.parse(s)
      rescue
        Rseed.logger.error "Could not parse datetime ".red + "'#{s}'"
      end

      return result
    end
  end
end