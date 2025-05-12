# frozen_string_literal: true

require "verse/http"

module Verse
  module JsonApi
    class Renderer
      attr_accessor :field_set, :pretty, :meta

      def initialize
        @field_set = []
        @pretty = true
      end

      def fields=(fields)
        @fields = fields.each_with_object({}) do |(key, list), h|
          h[key.to_sym] = Set.new(list.map(&:to_sym))
          h
        end
      end

      def fields
        @fields || {}
      end

      def render(object, server)
        server.content_type(server.content_type || "application/vnd.api+json")\

        # rubocop:disable Style/EmptyElse
        case object
        when Verse::Error::Base
          server.response.status = object.class.http_code
        when Exception
          server.response.status = 500
        else
          # keep status as-is
        end
        # rubocop:enable Style/EmptyElse

        output = \
          case object
          when Verse::Model::Record::Base
            included = gather_included(object)

            out = {}
            out[:data] = render_record(object, field_set, false)

            unless included.empty?
              out[:included] = included.map{ |r| render_record(r, field_set, false) }
            end

            out
          when Array, Verse::Util::ArrayWithMetadata
            render_collection(object, field_set)
          when Exception
            render_error_object(object)
          else
            { data: object }
          end

        if meta
          output[:meta] ||= {}
          output[:meta].merge!(meta)
        end

        @pretty ? JSON.pretty_generate(output) : JSON.generate(output)
      end

      def render_error(error, server)
        output = render_error_object(error)

        if error.class.respond_to?(:http_code)
          server.response.status = error.class.http_code
        else
          server.response.status = 500
        end

        @pretty ? JSON.pretty_generate(output) : JSON.generate(output)
      end

      protected

      def render_error_object(error)
        output = \
          case error
          when Verse::Error::ValidationFailed
            if error.source
              {
                errors: error.source.map do |key, values|
                  key = key.to_s

                  values.map do |value|
                    {
                      status: 422,
                      title: "Verse::Error::ValidationFailed",
                      detail: value,
                      source: { pointer: "/#{key.gsub(".", "/")}" }
                    }
                  end
                end.flatten
              }
            else
              {
                errors: [
                  {
                    status: 422,
                    title: "Verse::Error::ValidationFailed",
                    detail: error.message
                  }
                ]
              }
            end
          when Verse::Error::Base
            {
              errors: [
                {
                  status: error.class.http_code.to_s,
                  title: error.class.name,
                  detail: error.message,
                }
              ]
            }
          else
            {
              errors: [
                {
                  status: "500",
                  title: error.class.name,
                  detail: error.message,
                }
              ],
            }
          end

        if Verse::Http::Plugin.show_error_details?
          output[:meta] = { backtrace: error.backtrace }
        end

        output
      end

      def render_collection(arr, field_set)
        return { data: [], meta: render_metadata(arr) } if arr.empty?

        included = Set.new
        arr.each do |item|
          gather_included(item, true, included)
        end
        included = included.map{ |r| render_record(r, field_set, false) }

        {
          data: arr.map{ |v| render_record(v, field_set, false) },
          included: included.empty? ? nil : included,
          meta: render_metadata(arr)
        }.compact
      end

      # rubocop:disable Style/OptionalBooleanParameter
      def gather_included(record, root = true, include_set = Set.new)
        return unless record.is_a?(Verse::Model::Record::Base)

        if !root
          # Prevent circular references
          return include_set if include_set.include?(record)

          include_set.add(record)
        end

        record.relations.each_key do |key|
          relations = record.send(key)
          next if relations.nil?

          case relations
          when Array
            relations.each do |data|
              gather_included(data, false, include_set)
            end
          else
            gather_included(relations, false, include_set)
          end
        end

        include_set
      end
      # rubocop:enable Style/OptionalBooleanParameter

      def render_record(record, field_set, link)
        out = {
          type: record.type,
          id: record.id.to_s,
        }

        unless link
          out.merge!({
            attributes: render_attributes(record, field_set),
            relationships: render_relationships(record, field_set)
          }.compact)
        end

        out
      end

      def render_attributes(record, field_set)
        type = record.type.to_sym
        render_fields = @fields&.fetch(type, nil)

        record.class.fields.except(:id, :type).each_with_object({}) do |(field, key), h|
          next h if render_fields && !render_fields.include?(field)

          unless key.fetch(:visible, true) == true || field_set.include?(key[:visible])
            next h
          end

          value = record.send(field)

          h[field] = value
        end
      end

      def render_relationships(record, field_set)
        relationships = {}

        # Render explicitly included relationships
        record.class.relations.slice(*record.local_included.map(&:to_sym)).each do |key, value|
          relations = record.send(key)

          next unless relations

          if value.opts[:array]
            content = relations.map{ |r| render_record(r, field_set, true) }
            relationships[key] = { data: content }
          else
            relationships[key] = { data: relations && render_record(relations, field_set, true) }
          end
        end

        # Render belongs_to relationships that aren't explicitly included
        record.class.relations.each do |key, value|
          next if record.local_included.include?(key.to_s)
          next unless value.opts[:type] == :belongs_to

          foreign_key = value.opts[:foreign_key].to_sym
          foreign_id = record[foreign_key]

          next if foreign_id.nil?

          # Get the related record class and its type
          repository = value.opts[:repository]
          repository = Verse::Util::Reflection.constantize(repository) if repository.is_a?(String)
          related_record_class = value.opts[:record] || repository.model_class
          related_record_class = Verse::Util::Reflection.constantize(related_record_class) if related_record_class.is_a?(String)

          relationships[key] = {
            data: {
              type: related_record_class.type,
              id: foreign_id.to_s
            }
          }
        end

        relationships.empty? ? nil : relationships
      end

      def render_metadata(object)
        object.respond_to?(:metadata) ? object.metadata : nil
      end
    end
  end
end
