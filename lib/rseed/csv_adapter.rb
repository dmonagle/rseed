require 'colorize'

module Rseed
  class CsvAdapter < Rseed::Adapter
    attr_accessor :file

    def preprocess
      return false unless file
      logger.info "Preprocessing CSV file: #{file.to_s.yellow}"
      @estimated_rows = CSV.read(file).length - 1
      logger.info "Estimated Rows: #{@estimated_rows}".magenta
      true
    end

    def process &block
      headers = {}
      header = true
      data_count = 0
      row_number = 0

      # Get an estimate of the number of rows in the file
      CSV.foreach(file, {:encoding => 'windows-1251:utf-8'}) do |row|
        row_number += 1
        if (header)
          column = 0
          row.each do |column_value|
            column += 1
            converter_attributes.each do |attribute|
              if attribute.matches? column_value
                logger.debug "Found header for #{attribute.name} at column #{column}".green
                if (headers[attribute.name].nil?)
                  headers[attribute.name] = column
                else
                  logger.error "Found duplicate header '#{attribute.name}' on columns #{column} and #{headers[attribute.name]}.".red
                end
              end
            end
          end
          unless all_headers_found(headers)
            logger.error "Missing headers".red
            break
          end
          header = false
        else
          import_row = {}
          headers.each_pair do |name, column|
            value = row[column - 1].to_s
            import_row[name] = value
          end
          data_count += 1
          yield import_row, record_count: data_count, total_records: @estimated_rows
        end
      end
    end

    def all_headers_found(headers)
      @missing_headers_mandatory = []
      @missing_headers_optional = []
      found_at_least_one = false

      converter_attributes.each do |attribute|
        if headers[attribute.name].nil?
          unless attribute.options[:optional]
            @missing_headers_mandatory << attribute.name
          else
            @missing_headers_optional << attribute.name
          end
        else
          found_at_least_one = true
        end
      end
      if found_at_least_one
        logger.warn "Missing optional headers: #{@missing_headers_optional.join(',')}".yellow unless @missing_headers_optional.empty?
        logger.warn "Missing mandatory headers: #{@missing_headers_mandatory.join(',')}".red unless @missing_headers_mandatory.empty?
      end
      return false unless @missing_headers_mandatory.empty?
      true
    end
  end
end