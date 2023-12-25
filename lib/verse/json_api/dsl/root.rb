require_relative "./helper"
require_relative "./create"
require_relative "./delete"

module Verse
  module JsonApi
    module Dsl
      class Root
        extend Helper

        attr_reader :exposition_class, :resource_class

        instruction :path, ""
        instruction :service, :service

        def initialize(exposition_class, resource_class, &block)
          @exposition_class = exposition_class
          @resource_class   = resource_class
          instance_eval(&block)
        end

        # Declare a JSON::API create route for this exposition.
        def create(&block)
          Create.new(@exposition_class, self, &block)
        end

        # Declare a JSON::API delete route for this exposition.
        def delete(&block)
          Delete.new(@exposition_class, self, &block)
        end
      end
    end
  end
end