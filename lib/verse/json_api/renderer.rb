# frozen_string_literal: true

module Verse
  module JsonApi
    class Renderer
      attr_accessor :type, :primary_key, :field_set

      def initialize
        @type = "objects"
        @primary_key = "id"
        @field_set = []
      end

      def render(object, field_set = nil)
        field_set ||= self.field_set

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
          render_error(object)
        else
          render_custom(object)
        end
      end

      def render_error(error)
        case error
        when Verse::Error::Base
          raise "TODO"
        else
          raise "TODO"
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

      def render_custom(object)
        {
          type: self.type,
          id: object[self.primary_key]&.to_s,
          attributes: object.except(
            self.primary_key.to_s,
            self.primary_key.to_sym
          )
        }
      end

      def render_metadata(object)
        object.respond_to?(:metadata) ? object.metadata : nil
      end

      def render_model(object)
        included = render_included(object, object.included).uniq

        {
          data: render_object(object),
          meta: render_metadata(object)
        }.compact
      end


      def render_included(object, included)
        object.relations.each_key do |key|
          relations = object.relations[key]
          next if relations.nil?

          binding.pry

          type = key.to_s.gsub(/_record$/, "").pluralize
          case relations
          when Array
            relations.each do |data|
              data[:type] = type
              included << render_included_object(data)
              render_included(data, included)
            end
          else
            relations[:type] = type
            included << render_included_object(relations)
            render_included(relations, included)
          end
        end

        included.empty? ? nil : included.uniq
      end

      def render_included_object(object)
        {
          type: object.type,
          id: object.id.to_s,
          attributes: render_attributes(object),
          relationships: render_relationships(object)
        }
      end

    end
  end
end
