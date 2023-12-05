module Verse
  module JsonApi
    # Inspired by https://github.com/obrok/closed_struct/blob/master/lib/closed_struct.rb
    class ClosedStruct
      def initialize(contents, &block)
        @contents = contents.transform_keys(&:to_sym)

        singleton_class = (class << self; self; end)
        singleton_class.class_eval(&block) if block_given?
      end

      def method_missing(method_name, *args, &block)
        super if args.any? || block_given?
        @contents.fetch(method_name.to_sym){ super }
      end

      def respond_to_missing?(method_name, include_private = false)
        @contents.key?(method_name.to_sym) || super
      end

      def __update(key, value)
        @contents[key.to_sym] = value
      end

      def __arr_to_h(arr)
        arr.map do |elm|
          case elm
          when Array
            __arr_to_h(elm)
          when ClosedStruct
            elm.to_h
          else
            elm
          end
        end
      end

      def to_h
        @contents.transform_values do |value|
          case value
          when Array
            __arr_to_h value
          when ClosedStruct
            value.to_h
          else
            value
          end
        end
      end

      def hash
        @contents.hash
      end

      def ==(other)
        (other.class == self.class) && (other.to_h == self.to_h)
      end
      alias_method :eql?, :==

      def empty?
        @contents.empty?
      end

      def each_pair
        return enum_for(:each_pair) unless block_given?

        @contents.each_pair do |key, value|
          yield key, value
        end
      end
    end
  end
end