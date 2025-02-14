module Verse
  module JsonApi
    module Util
      extend self

      include Deserializer

      # Build a Verse::Schema::Base object
      # from a Verse::Model::Record::Base class.
      #
      # @param record [Class] the record class
      # @return [Verse::Schema::Base] the schema
      def jsonapi_record(record)
        Verse::Schema.define do

          field(:data, Hash) do
            field(:type, String).filled

            field?(:id, String)
            field?(:attributes, Hash) do
              record.fields.each do |name, field|
                next if field == :id
                next unless field[:visible]

                type = field.fetch(:type, Object)

                f = field?(name, type)
                f.meta(**field[:meta]) if field[:meta]
              end
            end

            field?(:relationships, Hash)
          end

          field?(:included, Array, of: Hash)
        end
      end

      # Build a Verse::Schema::Base object
      # representing a JSON:API collection output
      # from a Verse::Model::Record::Base class.
      #
      # @param record [Class] the record class
      # @return [Verse::Schema::Base] the schema
      def jsonapi_collection(record)
        Verse::Schema.define do
          field(:data, Array) do
            field(:type, String).filled

            field?(:id, String)
            field?(:attributes, Hash) do
              record.fields.each do |name, field|
                next if field == :id
                next unless field[:visible]

                type = field.fetch(:type, Object)

                f = field?(name, type)
                f.meta(**field[:meta]) if field[:meta]
              end
            end

            field?(:relationships, Hash)
          end

          field?(:included, Array, of: Hash)
        end
      end

    end
  end
end
