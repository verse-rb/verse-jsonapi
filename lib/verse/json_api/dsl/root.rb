# frozen_string_literal: true

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

        attr_reader :exposition_class, :resource_class, :http_opts

        instruction :path, ""
        instruction :service, :service
        instruction :allowed_included, [], type: :array

        def initialize(exposition_class, resource_class, http_opts, &block)
          @exposition_class = exposition_class
          @resource_class   = resource_class
          @http_opts = http_opts
          instance_eval(&block)
        end

        # Defines a base schema for endpoints such as "/resource/:id/nested_resource".
        #
        # This method yields the given block to `Verse::Schema.define` to create a schema.
        #
        # @example Allow the :id field to be an Integer
        #   base_schema do
        #     field(:id, Integer)
        #   end
        #
        # @yield [block] The block that defines the schema.
        # @yieldreturn [Verse::Schema] The defined schema.
        #
        # @return [Verse::Schema] The base schema.
        def base_schema(&block)
          if block
            @base_schema = Verse::Schema.define(&block)
          else
            @base_schema
          end
        end

        # Declares a JSON:API create route for this exposition.
        #
        # Instantiates a new {Create} object, initializing it with the exposition class,
        # the current context, and the provided block.
        #
        # @yield [block] A block to configure the create route.
        # @yieldparam [Create] create The create route object.
        def create(&block)
          Create.new(@exposition_class, self, &block)
        end

        # Declares a JSON:API delete route for this exposition.
        #
        # Instantiates a new {Delete} object, initializing it with the exposition class,
        # the current context, and the provided block.
        #
        # @yield [block] A block to configure the delete route.
        # @yieldparam [Delete] delete The delete route object.
        def delete(&block)
          Delete.new(@exposition_class, self, &block)
        end

        # Declares a JSON:API index route for this exposition.
        #
        # Instantiates a new {Index} object, initializing it with the exposition class,
        # the current context, and the provided block.
        #
        # @yield [block] A block to configure the index route.
        # @yieldparam [Index] index The index route object.
        def index(&block)
          Index.new(@exposition_class, self, &block)
        end

        # Declares a JSON:API show route for this exposition.
        #
        # Instantiates a new {Show} object, initializing it with the exposition class,
        # the current context, and the provided block.
        #
        # @yield [block] A block to configure the show route.
        # @yieldparam [Show] show The show route object.
        def show(&block)
          Show.new(@exposition_class, self, &block)
        end

        # Declares a JSON:API update route for this exposition.
        #
        # Instantiates a new {Update} object, initializing it with the exposition class,
        # the current context, and the provided block.
        #
        # @yield [block] A block to configure the update route.
        # @yieldparam [Update] update The update route object.
        def update(&block)
          Update.new(@exposition_class, self, &block)
        end
      end
    end
  end
end
