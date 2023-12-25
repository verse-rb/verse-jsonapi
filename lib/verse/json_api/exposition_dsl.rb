require_relative "dsl/root"

module Verse
  module JsonApi
    module ExpositionDsl

      def json_api(resource, &block)
        Dsl::Root.new(self, resource, &block)
      end

    end
  end
end

Verse::Exposition::Base.extend(Verse::JsonApi::ExpositionDsl)

      # class Context
      #   DEFAULT_ALLOWED_SORT = %i[id created_at updated_at].freeze

      #   attr_reader :actions

      #   def initialize(resource_class)
      #     @resource_class = resource_class
      #     @service = :service
      #     @actions = []
      #   end

      #   def service(service_name)
      #     @service = service_name.to_sym
      #   end

      #   def actions(*actions)
      #     @actions = actions
      #   end

      #   def allow_filters(**filters)
      #     @allowed_filters = filters
      #   end

      #   def reject_filters(*filters)
      #     @rejected_filters = filters.map(&:to_sym)
      #   end

      #   def allow_fieldset(*fields)
      #     @allowed_fieldset = fields.map(&:to_sym)
      #   end

      #   def allow_include(*includes)
      #     @allowed_include = includes
      #   end

      #   def allow_sort(*sorts)
      #     @allowed_sort = sorts.map(&:to_sym)
      #   end

      #   def generate(exposition_class)

      #   end

      #   protected

      #   def generate_list
      #     exposition_class.class_eval do
      #       # list
      #       expose on_http(:get, "/", renderer: Verse::JsonApi::Renderer) do
      #         desc "List #{resource_class.type}"
      #         input list_schema
      #       end
      #       def list
      #         value = deserialize(params)

      #         service.list(value,
      #           filter: params.fetch(:filter, {}),
      #           params: params.fetch(:sort, nil),
      #           include: params.fetch(:include, []),
      #           fieldset: params.fetch(:fieldset, :default)
      #         )
      #       end
      #     end

      #   end

      #   def list_schema
      #     Dry::Schema.Params do
      #       optional(:filter).hash do
      #         @allowed_filters.each do |field, type|
      #           optional(field, type)
      #         end
      #       end

      #       optional(:sort).value(:str?, included_in?: allowed_sort)
      #       optional(:include).array(:str?, included_in?: allowed_include)
      #       optional(:fieldset).value(:str?, included_in?: allowed_fieldset)
      #     end
      #   end

      #   def show_schema
      #     Dry::Schema.Params do
      #       optional(:include).array(:str?, included_in?: allowed_include)
      #       optional(:fieldset).value(:str?, included_in?: allowed_fieldset)
      #     end
      #   end

      #   def create_schema
      #     Dry::Schema.Params do
      #       required(:data).hash do
      #         required(:type).value(:str?, included_in?: resource_class.type)
      #         required(:attributes).hash do
      #           resource_class.attributes.each do |field, type|
      #             optional(field, type)
      #           end
      #         end
      #       end
      #     end
      #   end

      #   def update_schema
      #     Dry::Schema.Params do
      #       required(:data).hash do
      #         required(:type).value(:str?, included_in?: resource_class.type)
      #         required(:id).value(:str?)
      #         required(:attributes).hash do
      #           resource_class.attributes.each do |field, type|
      #             optional(field, type)
      #           end
      #         end
      #         optional(:relationships).hash do
      #           resource_class.relationships.each do |field, type|
      #             optional(field, type)
      #           end
      #         end
      #       end
      #     end
      #   end

      # end


