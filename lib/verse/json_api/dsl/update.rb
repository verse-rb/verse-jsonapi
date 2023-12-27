module Verse
  module JsonApi
    module Dsl
      class Update
        extend Helper

        attr_reader :parent, :exposition_class

        def initialize(exposition_class, parent, &block)
          @exposition_class = exposition_class
          @parent = parent

          instance_eval(&block) if block_given?
          install
        end

        instruction :path, ":resource_id"
        instruction :method, :patch

        instruction :ignored_fields, []

        instruction :authorized_relationships, []

        instruction :body
        instruction :schema

        def install
          dsl = self

          body = @body || ->(value) {
            key_name = dsl.path[/:(\w+)/, 1]&.to_sym
            send(dsl.parent.service).update(params[key_name], value)
          }

          @exposition_class.class_eval do
            expose on_http(dsl.method, File.join(dsl.parent.path, dsl.path), renderer: Verse::JsonApi::Renderer) do
              desc "Update #{dsl.parent.resource_class.type}"
              input dsl.create_schema
            end
            define_method(:update) do
              value = Verse::JsonApi::Deserializer.deserialize(params)
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
            key_name = dsl.path[/:(\w+)/, 1]&.to_sym

            raise "incorrect path for update: `#{path}`" unless key_name

            required(key_name).value(:str?)
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