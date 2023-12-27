require_relative "./spec_data"

class TestService < Verse::Service::Base
  def create(params)
  end

  def delete(id)
  end

  def index(filters, included: [], page: 1, items_per_page: 10, sort: nil, query_count: false)

  end
end

class TestExposition < Verse::Exposition::Base

  http_path "/users"

  use_service TestService

  json_api UserRecord do
    # service :service

    create
    delete
    index do
      allowed_filters :name__match
    end
  end
end