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
            expose on_http(dsl.method, Helper.build_path(dsl.parent.path, dsl.path), renderer: Verse::JsonApi::Renderer) do
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
          Verse::Schema.define do
            field?(:page, Hash) do
              field(:number, Integer).default(1).rule("must be positive"){ |v| v > 0 }
              field(:size, Integer).default(dsl.max_items_per_pages).rule("must be between 1 and #{dsl.max_items_per_pages}"){ |v| v > 0 && v <= dsl.max_items_per_pages }
            end
            field?(:sort, String)
            field(:count, TrueClass).default(false)

            field?(:filter, Hash) do
              dsl.parent.resource_class.fields.each do |field|
                next if dsl.blacklist_filters.include?(field[0])
                field?(field[0], Object)
              end

              dsl.allowed_filters.each do |field|
                case field
                when Proc
                  field[1].call(field(field[0].to_sym))
                when String, Symbol
                  field?(field.to_sym, Object)
                end
              end
            end

            field?(:included, Array, of: String).rule("must be one of `#{dsl.parent.allowed_included.join(",")}`") do |arr|
              arr.all?{ |it| dsl.parent.allowed_included.include?(it) }
            end
          end
        end

      end
    end
  end
end