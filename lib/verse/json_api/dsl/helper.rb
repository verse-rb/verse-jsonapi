# frozen_string_literal: true

module Verse
  module JsonApi
    module Dsl
      module Helper
        extend self

        NOTHING = Object.new

        def build_path(*args)
          args.reject(&:empty?).map do |x|
            x != "/" && x[-1] == "/" ? x[0..-2] : x
          end.join("/")
        end

        def instruction(name, default_value = nil, type: :simple)
          case type
          when :simple
            define_method(name) do |value = NOTHING|
              if value != NOTHING
                instance_variable_set("@#{name}", value)
                self
              else
                instance_variable_get("@#{name}") || default_value
              end
            end

          when :hash
            define_method(name) do |**values|
              if values.any?
                instance_variable_set("@#{name}", values)
                self
              else
                instance_variable_get("@#{name}") || default_value
              end
            end

          when :proc
            define_method(name) do |&block|
              if block
                instance_variable_set("@#{name}", block)
                self
              else
                instance_variable_get("@#{name}") || default_value
              end
            end

          when :array
            define_method(name) do |*values|
              if values.any?
                instance_variable_set("@#{name}", values)
                self
              else
                instance_variable_get("@#{name}") || default_value
              end
            end
          end
        end
      end
    end
  end
end
