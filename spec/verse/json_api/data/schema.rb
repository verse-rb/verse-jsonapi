module ServiceSpec
  class TeamRecord < Verse::Model::Record::Base
    field :id, primary: true

    field :name, type: String
    field :leader_id, type: Integer

    has_many :users, repository: "ServiceSpec::UserRepository"
    belongs_to :leader, repository: "ServiceSpec::UserRepository", foreign_key: :leader_id
  end

  class TeamRepository < Verse::Model::InMemory::Repository
  end

  class UserRecord < Verse::Model::Record::Base
    field :id, primary: true

    field :first_name, type: String
    field :last_name, type: String

    field :team_id, type: Integer, visible: false

    belongs_to :team, repository: "ServiceSpec::TeamRepository"
    has_one :owned_team, foreign_key: :leader_id, repository: "ServiceSpec::TeamRepository"
  end

  class UserRepository < Verse::Model::InMemory::Repository
  end

  class UserService < Verse::Service::Base
    use_repo UserRepository

    include Verse::JsonApi::Service
  end
end