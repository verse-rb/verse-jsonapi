# frozen_string_literal: true

require_relative "./struct"
require_relative "./bad_format_error"

module Verse
  module JsonApi
    module Deserializer
      extend self

      # Transform a JSON:API formatted string to a Struct.
      # @param input [String|Hash] a JSON:API formatted string or already parsed hash
      # @return [Verse::JsonApi::Struct] a Struct with all the data
      #
      # @note: Works only for structure with `data` key; documents with `meta` or `errors` key are not
      #       supported yet. Also, `link` keys are ignored for simplification.
      def deserialize(input, object_reference_index = {})
        return input if input.is_a?(Struct) # Idempotence
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
            Struct.new(
              data.map{ |it| deserialize_data(it, object_reference_index, ref_operation_list) },
              nil,
              input[:meta]
            )
          when Hash
            out = deserialize_data(data, object_reference_index, ref_operation_list)

            if input[:meta]
              out.meta = input[:meta].merge(out.meta || {})
            end

            out
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

        out[:attributes] = data[:attributes].dup
        struct = Struct.new(out, nil, data[:meta])

        # prepare the postprocessing pointers:
        data[:relationships]&.each do |rel_name, rel_value|
          out[:relationships] ||= {}
          content = rel_value&.[](:data)

          case content
          when Array
            ref_operations << proc do
              out[:relationships][rel_name] = content.map do |it|
                object_reference_index.fetch( unique_key(it) ) do
                  deserialize_data(it, object_reference_index, ref_operations)
                end
              end
            end
          when Hash
            ref_operations << proc do
              out[:relationships][rel_name] = \
                object_reference_index.fetch(unique_key(content)) do
                  deserialize_data(content, object_reference_index, ref_operations)
                end
            end
          when nil
            out[:relationships][rel_name] = nil
          else
            __raise__ "relationship `#{rel_name}` type not expected: `#{rel_value.class.name}`"
          end
        end

        struct
      end

      def unique_key(obj)
        [obj.fetch(:type), obj.fetch(:id, "")]
      end

      def __raise__(message)
        raise BadFormatError, message
      end
    end
  end
end
