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

        instruction :authorized_relationships, {}

        instruction :body
        instruction :schema

        def install
          dsl = self

          body = @body || ->(value) {
            send(dsl.parent.service).create(value)
          }

          @exposition_class.class_eval do
            expose on_http(dsl.method, Helper.build_path(dsl.parent.path, dsl.path), renderer: Verse::JsonApi::Renderer) do
              desc "Create #{dsl.parent.resource_class.type}"
              input dsl.create_schema
            end
            define_method(:create) do
              server.response.status = 201
              instance_exec(params, &body)
            end
          end
        end

        def create_schema
          dsl = self

          schema = @schema || Verse::Schema.define do
            dsl.parent.resource_class.fields.each do |field, config|
              field_name = [field.to_s, field.to_sym]

              next unless (field_name & dsl.ignored_fields).empty?
              next unless (config[:visible])

              type = config.fetch(:type)
              type = Object unless config.is_a?(Class)

              field?(field, type)
            end
          end

          relations = Verse::Schema.define do
            authorized_relationship_names = dsl.authorized_relationships
            dsl.parent.resource_class.relations.each do |f, config|
              relationship_options = dsl.authorized_relationships[f]

              next unless relationship_options

              record = Verse::Schema.define do
                field(:data, Hash) do
                  field(:type, String).filled

                  if(relationship_options.include?(:link))
                    field?(:id, String)
                  end

                  if(relationship_options.include?(:create))
                    field?(:attributes, Hash)
                  end

                  rule([:id, :attributes], "must have either id or attributes") do |schema|
                    schema[:id].nil? ^ schema[:attributes].nil?
                  end
                end
              end

              if config.opts[:array]
                field(f, Array, of: record)
              else
                field(f, record)
              end
            end
          end

          Verse::Schema.define do
            field(:data, Hash) do
              field(:type, String).in?(dsl.parent.resource_class.type)
              field(:attributes, schema)
              field?(:relationships, relations)
            end

            transform { |schema| Deserializer.deserialize(schema) }
          end
        end

      end
    end
  end
end