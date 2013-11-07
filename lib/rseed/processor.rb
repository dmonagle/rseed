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

      @adapter = adapter
      @converter = converter
    end

    def logger
      @logger.nil? ? Rseed.logger : @logger
    end

    def deserialize options = {}, &block
      converter.logger = logger
      adapter.logger = logger
      adapter.converter = converter

      yield :preprocessing
      begin
        if @adapter.preprocess
          @converter.before_deserialize
          yield :processing
          start_time = Time.now
          adapter.process do |values, meta|
            result = {}
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

            # Calculate the ETA
            if meta[:record_count] and meta[:total_records]
              remaining = meta[:total_records] - meta[:record_count]
              tpr = (Time.now - start_time)/meta[:record_count]
              meta[:eta] = remaining * tpr
            end
            yield :processing, result, meta
          end
          @converter.after_deserialize
        else
          yield :error, {success: false, message: 'Preprocessing failed', error: @adapter.error}
        end
      rescue Exception => e
        yield :error, {success: false, message: 'Exception during preprocessing', error: e.message, backtrace: e.backtrace}
      end
      yield :complete
    end
  end
end