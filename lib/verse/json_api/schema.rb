module Verse
  module JsonApi
    module Schema
      extend self

      def jsonapi_schema(record_class)
        Dry::Schema.Params do
          record_class.fields.each do |field|
            required(:data).hash do
              required(:attributes).hash do
                optional(field.name)
              end
            end
          end
        end
      end
    end
  end
end
