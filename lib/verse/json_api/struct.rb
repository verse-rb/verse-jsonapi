require 'forwardable'

module Verse
  module JsonApi
    class Struct
      extend Forwardable

      module Helper
        extend self

        def arr_to_h(arr)
          arr.map do |elm|
            case elm
            when Array
              arr_to_h(elm)
            when Struct
              elm.to_h
            else
              elm
            end
          end
        end
      end

      attr_accessor :data, :meta, :errors

      def model?
        @data.is_a?(Hash) && @data[:attributes] || nil
      end

      def type
        @data[:type]
      end

      def id
        @data[:id]
      end

      def success?
        !@errors
      end

      def errors?
        !success?
      end

      def_delegators :@data, :[], :==, :hash

      def ==(other)
        (other.class == self.class) && (other.to_h == self.to_h)
      end

      alias_method :eql?, :==

      def method_missing(name, *args, &block)
        super if !(args.empty?) || block_given?

        if attributes&.key?(name)
          attributes[name]
        elsif relationships&.key?(name)
          relationships[name]
        elsif data&.is_a?(Hash) && data.key?(name)
          data[name]
        else
          super
        end
      end

      def to_h(root=true)
        x = \
          case
          when model?
            {
              type: type,
              id: id,

              attributes: attributes,
              relationships: relationships&.transform_values { |v|
                case v
                when Array
                  { data: v.map{ |x| x.to_h(false) } }
                else
                  { data: v&.to_h }
                end
              }
            }.compact
          when array?
            Helper.arr_to_h(@data)
          else
            @data
          end

        if root
          {
            data: x,
            meta: @meta,
          }.compact
        else
          x
        end
      end

      def attributes
        (@data&.is_a?(Hash) && @data[:attributes]) || nil
      end

      def relationships
        (@data&.is_a?(Hash) && @data[:relationships]) || nil
      end

      def respond_to_missing?(name, include_private = false)
        attributes&.key?(name) || relationships&.key?(name) || super
      end

      def array?
        @data.is_a?(Array)
      end

      def meta?
        !!@meta
      end

      def initialize(data = nil, error = nil, meta = nil, &block)
        @data = data
        @meta = meta
        @errors = error

        if block_given?
          singleton_class = (class << self; self; end)
          singleton_class.class_eval(&block)
        end
      end

    end
  end

end