module Verse
  module JsonApi
    module Dsl
      class Create
        extend Helper

        attr_reader :parent, :exposition_class

        def initialize(exposition_class, parent, &block)
          @exposition_class = exposition_class
          @parent = parent

          instance_eval(&block) if block_given?
          install
        end

        instruction :path, ""
        instruction :method, :post

        instruction :ignored_fields, []

        instruction :authorized_relationships, []

        instruction :body
        instruction :schema

        def install
          dsl = self

          body = @body || ->(value) {
            send(dsl.parent.service).create(value.attributes)
          }

          @exposition_class.class_eval do
            expose on_http(dsl.method, Helper.build_path(dsl.parent.path, dsl.path), renderer: Verse::JsonApi::Renderer) do
              desc "Create #{dsl.parent.resource_class.type}"
              input dsl.create_schema
            end
            define_method(:create) do
              value = Verse::JsonApi::Deserializer.deserialize(params)
              server.response.status = 201
              instance_exec(value, &body)
            end
          end
        end

        def create_schema
          dsl = self

          schema = @schema || proc do
            dsl.parent.resource_class.fields.each do |field, config|
              field_name = [field.to_s, field.to_sym]

              next unless (field_name & dsl.ignored_fields).empty?
              next unless (config[:visible])

              optional(field).value(type?: config.fetch(:type, Object))
            end
          end

          relations = proc do
            dsl.parent.resource_class.relations.each do |field, config|
              next unless dsl.authorized_relationships.include?(field)

              if config.opts[:array]
                required(field).array(:hash) do
                  required(:id).filled(:string)
                  required(:type).filled(:string)
                  optional(:attributes).hash
                end
              else
                required(field).hash do
                  required(:id).filled(:string)
                  required(:type).filled(:string)
                  optional(:attributes).hash
                end
              end
           end
          end

          Dry::Schema.Params do
            required(:data).hash do
              required(:type).value(:str?, included_in?: dsl.parent.resource_class.type)
              required(:attributes).hash(&schema)
              optional(:relationships).hash(&relations)
            end
          end
        end

      end
    end
  end
end