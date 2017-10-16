module Datadog
  InvalidOptionError = Class.new(StandardError)
  # Configurable provides configuration methods for a given class/module
  module Configurable
    IDENTITY = ->(x) { x }

    def self.included(base)
      base.singleton_class.send(:include, ClassMethods)
    end

    def merge_configuration(options, defaults = self.class)
      defaults.to_h.merge(options)
    end

    # ClassMethods
    module ClassMethods
      def set_option(name, value)
        __assert_valid!(name)

        __options[name][:value] = __options[name][:setter].call(value)
        __options[name][:set_flag] = true
      end

      def get_option(name)
        __assert_valid!(name)

        return __options[name][:default] unless __options[name][:set_flag]

        __options[name][:value]
      end

      def to_h
        __options.each_with_object({}) do |(key, _), hash|
          hash[key] = get_option(key)
        end
      end

      def reset_options!
        __options.each do |name, meta|
          set_option(name, meta[:default])
        end
      end

      private

      def option(name, meta = {})
        name = name.to_sym
        meta[:setter] ||= IDENTITY
        __options[name] = meta
      end

      def __options
        @__options ||= {}
      end

      def __assert_valid!(name)
        return if __options.key?(name)
        raise(InvalidOptionError, "#{__pretty_name} doesn't have the option: #{name}")
      end

      def __pretty_name
        entry = Datadog.registry.find { |el| el.klass == self }

        return entry.name if entry

        to_s
      end
    end
  end
end