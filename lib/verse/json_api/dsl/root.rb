require_relative "./helper"
require_relative "./create"
require_relative "./delete"
require_relative "./index"
require_relative "./show"
require_relative "./update"

module Verse
  module JsonApi
    module Dsl
      class Root
        extend Helper

        attr_reader :exposition_class, :resource_class

        instruction :path, ""
        instruction :service, :service
        instruction :allowed_included, []
        instruction :key_type, proc{ |key| key.filled(:integer) }

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

        def index(&block)
          Index.new(@exposition_class, self, &block)
        end

        def show(&block)
          Show.new(@exposition_class, self, &block)
        end

        def update(&block)
          Update.new(@exposition_class, self, &block)
        end
      end
    end
  end
end