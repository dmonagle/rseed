require 'rails/generators'

module Rseed
  module Generators
    class ConverterGenerator < Rails::Generators::NamedBase
      class_option :converter_name, :type => :string, :default => nil, :desc => "Names the converter file, defaults to the model name"
      class_option :attribute, :type => :string, :default => nil, :desc => "If set will default to a first_or_initialize for creation of the model."
      class_option :minimal, :type => :boolean, :default => false, :desc => "Create a converter with less template code and less comments"

      def self.source_root
        @source_root ||= File.join(File.dirname(__FILE__), 'templates')
      end

      def create_files
        converter_dir = File.join("app", "rseed")
        seed_dir = File.join("db", "rseed")
        Dir.mkdir(converter_dir) unless File.directory?(converter_dir)
        @model_name = file_name
        @class_name = class_name
        @model = eval(@class_name)
        @columns = @model.columns_hash.except "id", "created_at", "updated_at"
        @relationships = {}
        @model.reflect_on_all_associations.each do |relationship|
          if relationship.macro == :belongs_to
            @relationships[relationship.name] = relationship
            @columns.delete(relationship.foreign_key)
          end
        end
        @converter_name = options.converter_name || @class_name
        @match_attribute = options.attribute
        @minimal = options.minimal

        template 'converter.rb.erb', File.join(converter_dir, "#{@converter_name.underscore}_converter.rb")
        Dir.mkdir(seed_dir) unless File.directory?(seed_dir)
        template 'data.csv.erb', File.join(seed_dir, "#{@converter_name.underscore.pluralize}.csv")
      end
    end
  end
end
