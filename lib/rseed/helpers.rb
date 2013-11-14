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
    title = options[:title] ? options[:title].dup : "Seed"
    title = "#{processor.converter.name.cyan} #{title.blue}"
    record_count = 0
    progress_bar = ProgressBar.create(starting_at: nil, total: nil, format: "#{"Preprocessing".magenta} %t <%B>", title: title, throttle_rate: 1)
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
          progress_bar.finish if progress_bar.total
        when :error
          processor.logger.error "Error during processing"
          processor.logger.error result[:message].to_s.red
          processor.logger.error meta.to_s.cyan if meta
          processor.logger.error result[:error]
          processor.logger.error result[:backtrace].join('\n') if result[:backtrace]
      end
    end
  end

  def from_file file, options = {}
    unless f = import_file(file)
      logger.error "Cannot locate file: ".red + file.to_s
      return false
    end
    p = Processor.new(options)
    return nil unless p
    p.adapter.file = f
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

  def import_file(file)
    return file if File.exists? file
    # Try it relative to the rseed directory
    rseed_file = File.join(Rails.root, 'db', 'rseed', file)
    return rseed_file if File.exists? rseed_file
    # Try it relative to the Rails directory
    rails_file = File.join(Rails.root, file)
    return rails_file if File.exists? rails_file
    nil
  end

  module_function :from_file
  module_function :from_hash
  module_function :from_csv
  module_function :process_with_status_bar
  module_function :import_file
end