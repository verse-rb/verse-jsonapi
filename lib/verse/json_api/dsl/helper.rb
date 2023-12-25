module Verse
  module JsonApi
    module Dsl
      module Helper
        extend self

        NOTHING = Object.new

        def instruction(name, default_value = nil)
          define_method(name) do |value = NOTHING, &block|
            case
            when block
              instance_variable_set("@#{name}", block)
              self
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