module Rseed
  class Processor
    attr_writer :logger
    attr_reader :adapter
    attr_reader :converter

    def initialize(options = {})
      return nil unless options[:adapter]
      return nil unless options[:converter]

      adapter = options[:adapter].is_a?(Adapter) ? options[:adapter] : Rseed.const_get("#{options[:adapter].to_s.classify}Adapter").new
      converter = options[:converter].is_a?(Converter) ? options[:converter] : Rseed.const_get("#{options[:converter].to_s.classify}Converter").new
      converter.options = deserialize_converter_options(options[:converter_options])if options[:converter_options]
      @within_transaction = options[:within_transaction]
      @adapter = adapter
      @converter = converter
    end

    def logger
      @logger.nil? ? Rseed.logger : @logger
    end

    def deserialize options = {}, &block
      total_records = 0
      record_count = 0

      converter.logger = logger
      adapter.logger = logger
      adapter.converter = converter

      begin
        logger.info "Converter: #{@converter.name.cyan}"
        logger.info "Converter Options: #{@converter.options.to_s.dup.cyan}"
        yield :preprocessing
        if @adapter.preprocess
          if @converter.before_deserialize
            yield :processing
            start_time = Time.now
            wrap_inserts do
              adapter.process do |values, meta|
                result = {values: values}
                meta ||= {}
                begin
                  if @converter.deserialize_raw(values)
                    result[:success] = true
                  else
                    result[:success] = false
                    result[:message] = "Failed to convert"
                    result[:error] = @converter.error
                  end
                rescue Exception => e
                  result[:success] = false
                  result[:message] = "Exception during deserialize"
                  result[:error] = e.message
                  result[:backtrace] = e.backtrace
                end

                total_records = meta[:total_records] unless meta[:total_records].nil?
                record_count = meta[:record_count] unless meta[:record_count].nil?
                # Calculate the ETA
                if record_count and total_records
                  remaining = total_records - record_count
                  tpr = (Time.now - start_time)/record_count
                  meta[:eta] = remaining * tpr
                end

                # Log any errors
                unless result[:success]
                  logger.error result[:message].to_s.red
                  logger.error result[:error].to_s.red
                  logger.error meta.to_s.cyan
                  logger.error result[:backtrace].to_s unless result[:backtrace].to_s.blank?
                end
                yield :processing, result, meta
              end
              @converter.after_deserialize
            end
          else
            yield :error, {success: false, message: 'Before deserialize failed', error: @converter.error}
          end
        else
          yield :error, {success: false, message: 'Preprocessing failed', error: @adapter.error}
        end
      rescue Exception => e
        yield :error, {success: false, message: 'Exception during Processing', error: e.message, backtrace: e.backtrace}
      end
      yield :complete, {success: true}, {total_records: total_records, record_count: record_count}
    end

    protected

    def wrap_inserts &block
      if @within_transaction
        ActiveRecord::Base.transaction do
          yield
        end
      else
        yield
      end
    end

    def deserialize_converter_options converter_options
      if converter_options.is_a? String
        co = converter_options.split(";")
        converter_options = {}
        co.each do |option|
          s = option.split("=")
          converter_options[s[0].strip] = s[1].strip
        end
      end
      HashWithIndifferentAccess.new(converter_options)
    end
  end
end