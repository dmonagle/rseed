module Rseed
  class Adapter
    attr_writer :logger
    attr_writer :options
    attr_reader :error
    attr_accessor :converter

    def logger
      @logger.nil? ? Rseed.logger : @logger
    end

    def options
      @options.nil? ? {} : @options
    end

    def converter_attributes
      return [] unless converter
      converter.class.converter_attributes
    end

    def mandatory_attributes
      return [] unless converter
      converter.class.mandatory_attributes
    end

    # Dummy process that should be overwritten by other adapters
    def preprocess
      return true
    end

    def process &block
      values = {}
      meta = {}
      yield values, meta
    end
  end
end