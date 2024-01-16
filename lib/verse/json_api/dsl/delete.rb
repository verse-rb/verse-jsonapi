module Verse
  module JsonApi
    module Dsl
      class Delete
        extend Helper

        attr_reader :parent, :exposition_class

        def initialize(exposition_class, parent, &block)
          @exposition_class = exposition_class
          @parent = parent

          instance_eval(&block) if block_given?
          install
        end

        instruction :path, ":resource_id"
        instruction :method, :delete

        instruction :body
        instruction :schema

        def install
          dsl = self

          body = @body || ->(service) {
            key_name = dsl.path[/:(\w+)/, 1]&.to_sym
            server.response.status = 204
            service.delete(params[key_name.to_sym])
            server.no_content
          }

          @exposition_class.class_eval do
            expose on_http(dsl.method, Helper.build_path(dsl.parent.path, dsl.path), renderer: Verse::JsonApi::Renderer) do
              desc "Create #{dsl.parent.resource_class.type}"
              input dsl.create_schema
            end
            define_method(:delete) {
              service = send(dsl.parent.service) if respond_to?(dsl.parent.service)
              instance_exec(service, &body)
            }
          end
        end

        def create_schema
          key_name = path[/:(\w+)/, 1]&.to_sym

          raise "incorrect path for delete: `#{path}`" unless key_name

          Dry::Schema.Params do
            required(key_name).filled(:string)
          end
        end

      end
    end
  end
end