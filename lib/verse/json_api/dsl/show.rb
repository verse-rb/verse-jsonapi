# frozen_string_literal: true

module Verse
  module JsonApi
    module Dsl
      class Show
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

        def install
          dsl = self

          body = @body || ->(service) {
            key_name = dsl.path[/:(\w+)/, 1]&.to_sym
            service.show(params[key_name.to_sym], included: params.fetch(:included, []))
          }

          @exposition_class.class_eval do
            expose on_http(dsl.method, Helper.build_path(dsl.parent.path, dsl.path), renderer: Verse::JsonApi::Renderer) do
              desc "Show a specific #{dsl.parent.resource_class.type}"
              input dsl.create_schema
            end
            define_method(:show) {
              service = send(dsl.parent.service) if respond_to?(dsl.parent.service)
              instance_exec(service, &body)
            }
          end
        end

        def create_schema
          dsl = self
          Verse::Schema.define do
            key_name = dsl.path[/:(\w+)/, 1]&.to_sym

            raise "incorrect path for show: `#{path}`" unless key_name

            dsl.parent.key_type.call(field(key_name, Object))
            field?(:included, Array, of: String).rule("included unauthorized"){ |value| value.all?{ |v| dsl.parent.allowed_included.include?(v) } }
          end
        end
      end
    end
  end
end
