module Verse
  module JsonApi
    module Dsl
      class Index
        extend Helper

        attr_reader :parent, :exposition_class

        def initialize(exposition_class, parent, &block)
          @exposition_class = exposition_class
          @parent = parent

          instance_eval(&block) if block_given?
          install
        end

        instruction :path, ":resource_id"
        instruction :method, :get

        instruction :body

        instruction :max_items_per_pages, 1000

        def install
          dsl = self

          body = @body || ->(service) {
            service.index(
              params.fetch(:filter, {}),
              included: params.fetch(:included, []),
              page: params.fetch(:page, 1),
              items_per_page: params.fetch(:per_page, dsl.max_items_per_pages),
              sort: params&.fetch(:sort, nil)&.split(","),
              query_count: params.fetch(:count, false)
            )
          }

          @exposition_class.class_eval do
            expose on_http(dsl.method, File.join(dsl.parent.path, dsl.path), renderer: Verse::JsonApi::Renderer) do
              desc "List #{dsl.parent.resource_class.type}"
              input dsl.create_schema
            end
            define_method(:index) {
              service = send(dsl.parent.service) if respond_to?(dsl.parent.service)
              instance_exec(service, &body)
            }
          end
        end

        def create_schema
          dsl = self
          Dry::Schema.Params do
            key_name = path[/:(\w+)/, 1]&.to_sym

            raise "incorrect path for show: `#{path}`" unless key_name

            Dry::Schema.Params do
              required(key_name).filled(:string)
              optional(:included).array(:string, included_in?: dsl.parent.allowed_included)
            end
          end
        end

      end
    end
  end
end