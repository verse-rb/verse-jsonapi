module Verse
  module JsonApi
    module Dsl
      module Helper
        extend self

        NOTHING = Object.new

        def build_path(*args)
          args.reject(&:empty?).map do |x|
            x = (x != "/" && x[-1] == "/") ? x[0..-2] : x
          end.join("/")
        end

        def instruction(name, default_value = nil)
          case default_value
          when Hash
            define_method(name) do |*values|
              if values.any?
                instance_variable_set("@#{name}", values)
                self
              else
                instance_variable_get("@#{name}") || default_value
              end
            end
          when Proc
            define_method(name) do |&block|
              if block_given?
                instance_variable_set("@#{name}", block)
                self
              else
                instance_variable_get("@#{name}") || default_value
              end
            end
          when Array
            define_method(name) do |*values|
              if values.any?
                instance_variable_set("@#{name}", values)
                self
              else
                instance_variable_get("@#{name}") || default_value
              end
            end
          else
            define_method(name) do |value = NOTHING|
              case
              when value != NOTHING
                instance_variable_set("@#{name}", value)
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