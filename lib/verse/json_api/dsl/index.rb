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

        instruction :path, ""
        instruction :method, :get

        instruction :body

        instruction :allowed_filters, []
        instruction :blacklist_filters, []

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
            optional(:page).value(:integer).value(gt?: 0)
            optional(:per_page).value(:integer).value(gt?: 0, lt?: dsl.max_items_per_pages + 1)
            optional(:sort).value(:string)
            optional(:count).value(:bool)

            optional(:filter).hash do
              dsl.parent.resource_class.fields.each do |field|
                next if dsl.blacklist_filters.include?(field[0])
                optional(field[0]).value(type?: Object)
              end

              dsl.allowed_filters.each do |field|
                case field
                when Proc
                  field[1].call(optional(field[0].to_sym))
                when String, Symbol
                  optional(field.to_sym).value(type?: Object)
                end
              end
            end

            optional(:included).array(:string)
          end
        end

      end
    end
  end
end