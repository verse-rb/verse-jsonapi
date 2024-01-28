module Verse
  module JsonApi
    module Service

      def index(filter, included: [], page: 1, items_per_page: 1000, sort: nil, query_count: false)
        repo.index(
          filter,
          included: included,
          page: page,
          items_per_page: items_per_page,
          sort: sort,
          query_count: query_count
        )
      end

      def create(record)
        repo.transaction do
          attributes = record.attributes

          # 1) setup the belongs to links:
          repo.class.model_class.relations.each do |key, value|
            next unless value.opts[:type] == :belongs_to

            # 1.0) verify that the relation is tagged in the creation:
            next unless record.relationships
            next unless rel = record.relationships[key]

            # 1.1) setup repo:
            repo_class = value.opts[:repository]
            linked_repo = repo_class.new(auth_context)

            # 1.2) check if it's a new record or not:
            is_new = rel.id.nil?

            linked_record = \
              if is_new
                # 1.3a) create the record:
                id = linked_repo.create(rel.attributes)
                linked_repo.find!(id)
              else
                # 1.3b) find the record:
                begin
                  linked_repo.find!(rel.id)
                rescue Verse::Error::RecordNotFound
                  raise Verse::Error::ValidationFailed, "relation `#{key}`:#{rel.id} does not exist or is not accessible"
                end
              end

            # 1.4) setup the foreign key as id of the record:
            record.attributes[value.opts[:foreign_key]] = linked_record.id
          end

          id = repo.create(record.attributes)
          repo.find(id)
        end
      end

      def update(record)
        raise "not implemented"
      end

      def delete(id)
        raise "not implemented"
      end

      def show(id, included: [])
        repo.find!(id, included: included)
      end

    end
  end
end
