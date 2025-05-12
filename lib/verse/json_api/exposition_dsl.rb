# frozen_string_literal: true

require_relative "dsl/root"

module Verse
  module JsonApi
    module ExpositionDsl
      def json_api(resource, &block)
        Dsl::Root.new(self, resource, &block)
      end
    end
  end
end
