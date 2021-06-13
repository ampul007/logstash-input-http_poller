# encoding: utf-8
require "yaml" # persistence

module LogStash
  module Inputs
    class ValueTracking

      def self.build_last_value_tracker(plugin)
        handler = plugin.record_last_run ? FileHandler.new(plugin.last_run_metadata_path) : NullFileHandler.new(plugin.last_run_metadata_path)
        if plugin.record_last_run
          handler = FileHandler.new(plugin.last_run_metadata_path)
        end
        if plugin.clean_run
          handler.clean
        end
        DateTimeValueTracker.new(handler)
      end

      attr_reader :value

      def initialize(handler)
        @file_handler = handler
        set_initial
      end

      def set_initial
        # override in subclass
      end

      def set_value(value)
        # override in subclass
      end

      def write
        @file_handler.write(@value)
      end

      private

      def common_set_initial(method_symbol, default)
        persisted = @file_handler.read

        if persisted && persisted.respond_to?(method_symbol)
          @value = persisted
        else
          @file_handler.clean
          @value = default
        end
      end
    end

    class DateTimeValueTracker < ValueTracking
      def set_initial
        common_set_initial(:to_datetime, DateTime.now-(1380.0/1440.0))
      end

      def set_value(value)
        if value.respond_to?(:to_datetime)
          @value = value.to_datetime
        else
          @value = DateTime.parse(value)
        end
      end
    end


    class FileHandler
          attr_reader :path

      def initialize(path)
        @path = path
        @exists = ::File.exist?(@path)
      end

      def clean
        return unless @exists
        ::File.delete(@path)
        @exists = false
      end

      def read
        return unless @exists
        YAML.load(::File.read(@path))
      end

      def write(value)
        ::File.write(@path, YAML.dump(value))
        @exists = true
      end
    end

    class NullFileHandler
      def initialize(path)
      end

      def clean
      end

      def read
      end

      def write(value)
      end
    end
  end
end
