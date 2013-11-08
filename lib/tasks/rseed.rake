require "rseed"
require "colorize"

namespace :rseed do
  desc "Seed a CSV file using the CsvAdapter and a converter"
  task :csv => :environment do
    converter = ENV["converter"] || ENV["CONVERTER"]
    converter_options = ENV["converter_options"] || ENV["CONVERTER_OPTIONS"]
    file = ENV["file"] || ENV["FILE"]
    if file && converter
      options = {converter: converter}
      options[:converter_options] = converter_options if converter_options
      Rseed::from_csv file, options
    else
      puts "You must specify file=<file> and converter=<converter>".red
    end
  end
end
