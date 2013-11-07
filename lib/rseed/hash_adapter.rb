module Rseed
  class HashAdapter < Rseed::Adapter
    attr_accessor :data
    def initialize data = nil
      @data = data
    end

    def preprocess
      return false unless @data.is_a? Array or @data.is_a?(Hash)
      @data = [@data] if @data.is_a?(Hash)
      true
    end

    def process &block
      meta = {}
      meta[:total_records] = @data.length
      @data.each_with_index do |d, i|
        meta[:record_count] = i + 1
        yield d, meta
      end
    end
  end
end