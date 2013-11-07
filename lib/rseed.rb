require "csv"
require "rseed/attribute"
require "rseed/attribute_converters"
require "rseed/version"
require "rseed/adapter"
require "rseed/hash_adapter"
require "rseed/converter"
require "rseed/processor"
require "rseed/csv_adapter"
require "rseed/utilities"

module Rseed
  class << self
    attr_accessor :logger
  end

  @logger = Logger.new(STDOUT)

  class Railtie < ::Rails::Railtie
    railtie_name :rseed

    rake_tasks do
      load "tasks/rseed.rake"
    end

    generators do
      require "generators/rseed/converter"
    end
  end
end
