require 'ruby-progressbar'
require 'colorize'

module Rseed
  class ProgressBarLogger < IO
    def initialize(progress_bar)
      @progress_bar = progress_bar
    end

    def write(*args)
      @progress_bar.log args.join(',')
    end

    def close
    end
  end

  def process_with_status_bar processor, options = {}
    title = options[:title] ? options[:title] : "Seed"
    title = "#{processor.converter.name.cyan} #{title.blue}"
    record_count = 0
    progress_bar = ProgressBar.create(starting_at: nil, total: nil, format: "#{"Preprocessing".magenta} %t <%B>", title: title)
    processor.logger = Logger.new(ProgressBarLogger.new(progress_bar))
    processor.deserialize do |status, result, meta|
      eta = meta ? meta[:eta] : nil
      eta = eta ? Time.at(eta).utc.strftime("%H:%M:%S") : "??:??"
      case status
        when :processing
          progress_bar.format "#{"Processing".yellow} %t <%B> %c/%C (#{eta.to_s.yellow})"
          if meta
            if record_count != meta[:record_count]
              record_count = meta[:record_count]
              progress_bar.total ||= meta[:total_records]
              # Set the progress unless it is the finishing record.
              progress_bar.progress = record_count unless record_count == progress_bar.total
            end
          end
        when :complete
          progress_bar.format "#{"Complete".green} %t <%B> %C (%a)"
          progress_bar.finish
        when :error
          processor.logger.error result[:message].to_s.red
          processor.logger.error result[:error]
          processor.logger.error result[:backtrace].join('\n')
      end
    end
  end

  def from_file file, options = {}
    p = Processor.new(options)
    return nil unless p
    p.adapter.file = file
    process_with_status_bar p, title: file
  end

  def from_csv(file, options = {})
    options[:adapter] = :csv
    from_file(file, options)
  end

  def from_hash hash_or_array, options = {}
    p = Processor.new(adapter: :hash, converter: options[:converter])
    return nil unless p
    p.adapter.data = hash_or_array
    process_with_status_bar p, title: "Hash"
  end

  module_function :from_file
  module_function :from_hash
  module_function :from_csv
  module_function :process_with_status_bar
end