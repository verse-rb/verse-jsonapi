require_relative "./spec_data"

class TestService < Verse::Service::Base
  def create(params)
  end
end

class TestExposition < Verse::Exposition::Base

  http_path "/users"

  use_service TestService

  json_api UserRecord do
    # service :service

    create
    delete
  end
end