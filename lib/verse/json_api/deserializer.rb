require_relative "./closed_struct"
require_relative "./bad_format_error"

module Verse
  module JsonApi
    module Deserializer

      extend self


      # Transform a JSON:API formatted string to a ClosedStruct.
      # @param input [String|Hash] a JSON:API formatted string or already parsed hash
      # @return [Verse::ClosedStruct] a ClosedStruct with all the data
      #
      # @note: Works only for structure with `data` key; documents with `meta` or `errors` key are not
      #       supported yet. Also, `link` keys are ignored for simplification.
      def deserialize(input, object_reference_index = {})
        return deserialize(JSON.parse(input, symbolize_names: true), object_reference_index) if input.is_a?(String)

        if input[:errors]
          __raise__ "Object is error object: #{input[:errors].to_json}"
        end

        ref_operation_list = []

        input[:included]&.tap do |arr|
          arr.each do |object|
            object_reference_index[unique_key(object)] = deserialize_data(object, object_reference_index, ref_operation_list)
          end
        end

        data = input[:data]

        out = \
          case data
          when Array
            data.map{ |it| deserialize_data(it, object_reference_index, ref_operation_list) }
          when Hash
            deserialize_data(data, object_reference_index, ref_operation_list)
          else
            __raise__ "bad JSON:API format. Data must be of type Array|Hash, but `#{data.class.name}` is given"
          end

        # finalize by connecting objects together
        ref_operation_list.each(&:call)

        out
      end

      private

      def deserialize_data(data, object_reference_index, ref_operations)
        out = data.slice(:id, :type)

        data[:attributes]&.tap{ |att| out = att.merge(out) }

        # prepare the keys first.
        data[:relationships]&.each do |rel_name, _|
          out[rel_name] = nil
        end

        struct = ClosedStruct.new(out)

        # prepare the postprocessing pointers:
        data[:relationships]&.each do |rel_name, rel_value|
          out[rel_name] = nil
          content = rel_value&.[](:data)

          case content
          when Array
            ref_operations << -> {
              struct.__update(rel_name, content.map{ |it|
                object_reference_index.fetch( unique_key(it) ) do
                  deserialize_data(it, object_reference_index, ref_operations)
                end
              })
            }
          when Hash
            ref_operations << -> {
              struct.__update(rel_name, object_reference_index.fetch(unique_key(content)){
                deserialize_data(content, object_reference_index, ref_operations)
              })
            }
          when nil
            # do nothing
          else
            __raise__ "relationship `#{rel_name}` type not expected: `#{rel_value.class.name}`"
          end
        end

        struct
      end

      def unique_key(obj)
        [obj.fetch(:type), obj.fetch(:id, '')]
      end

      def __raise__(message)
        raise BadFormatError, message
      end
    end

  end
end