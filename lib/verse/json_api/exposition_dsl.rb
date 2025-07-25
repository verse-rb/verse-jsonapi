# frozen_string_literal: true

require_relative "dsl/root"

module Verse
  module JsonApi
    module ExpositionDsl
      def json_api(resource, http_opts: {}, &block)
        Dsl::Root.new(self, resource, http_opts, &block)
      end
    end
  end
end
