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

      def render(object, ctx)
        ctx.content_type(ctx.content_type || "application/vnd.api+json")

        case object
        when Verse::Error::Base
          ctx.status object.class.http_code
        when Exception
          ctx.status 500
        else
          # keep status as-is
        end

        output = \
          case object
          when Verse::Model::Record::Base
            included = gather_included(object)

            out = {}
            out[:data] = render_record(object, self.field_set, false)

            unless included.empty?
              out[:included] = included.map{ |r| render_record(r, self.field_set, false) }
            end

            out
          when Array, Verse::Util::ArrayWithMetadata
            render_collection(object, self.field_set)
          when Exception
            render_error(object)
          else
            { data: object }
          end

          if meta
            output[:meta] ||= {}
            output[:meta].merge!(meta)
          end

          @pretty ? JSON.pretty_generate(output) : output.to_json
      end

      def render_error(error)
        case error
        when Verse::Error::Base
          {
            errors: [
              {
                status: error.class.http_code.to_s,
                title:  error.class.name,
                detail: error.message,
                meta:{
                  backtrace: error.backtrace
                }
              }
            ]
          }
        else
          {
            errors: [
              {
                status: "500",
                title: error.class.name,
                detail:  error.message,
                meta:{
                  backtrace: error.backtrace
                }
              }
            ]
          }
        end
      end

      protected

      def render_collection(arr, field_set)
        return { data: arr } if arr.empty?

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
        record.class.fields.except(:id, :type).reduce({}) do |h, (field, key)|
          next h if !(
            key[:visible] || field_set.include?(key[:visible])
          )

          value = record.send(field)

          h[field] = value
          h
        end
      end

      def render_relationships(record, field_set)
        relationships = {}
        record.class.relations.slice(*record.included).each do |key, value|
          relations = record.send(key)

          next unless relations

          if value.opts[:array]
            if relations.nil?
              relationships[key] = {data: []}
            else
              relationships[key] = {
                data: relations.map { |r|
                  render_record(r, field_set, true)
                }
              }
            end
          else
            if relations.nil?
              relationships[key] = {
                data: nil
              }
            else
              relationships[key] = {
                data: render_record(relations, field_set, true)
              }
            end
          end
        end

        relationships.empty? ? nil : relationships
      end

      def render_metadata(object)
        object.respond_to?(:metadata) ? object.metadata : nil
      end

    end
  end
end
