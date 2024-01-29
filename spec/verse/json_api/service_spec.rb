require_relative "./data/schema"

RSpec.describe Verse::JsonApi::Service do
  let(:user_context) { :system }
  subject { ServiceSpec::UserService.new(Verse::Auth::Context[user_context]) }

  describe "#index" do
    it "returns a collection of users" do
      users = subject.index({})

      expect(users).to be_a(Verse::Util::ArrayWithMetadata)
      expect(users).to all(be_a(ServiceSpec::UserRecord))
    end
  end

  before do
    ServiceSpec::UserRepository.clear
    ServiceSpec::TeamRepository.clear
  end

  describe "#create" do
    context "with belongs_to association" do
      it "creates a user with a new team" do
        user_data = Verse::JsonApi::Deserializer.deserialize({
          data: {
            type: "users",
            attributes: {
              first_name: "John",
              last_name: "Doe"
            },
            relationships: {
              team: {
                data: {
                  type: "teams",
                  attributes: {
                    name: "Team 1"
                  }
                }
              }
            }
          }
        })

        user = subject.create(user_data)

        expect(ServiceSpec::TeamRepository.data).to eq(
          [
            {
              id: 1,
              name: "Team 1",
            }
          ]
        )

        expect(user).to be_a(ServiceSpec::UserRecord)
        expect(user.id).to_not be_nil
        expect(user.first_name).to eq("John")
      end

      it "assigns an existing team" do
        team = ServiceSpec::TeamRecord.new({ id: 1, name: "Team 1" })
        ServiceSpec::TeamRepository.data = [team]

        user_data = Verse::JsonApi::Deserializer.deserialize({
          data: {
            type: "users",
            attributes: {
              first_name: "John",
              last_name: "Doe"
            },
            relationships: {
              team: {
                data: {
                  type: "teams",
                  id: 1
                }
              }
            }
          }
        })

        subject.create(user_data)

        user = subject.show(1, included: ["team"])

        expect(user).to be_a(ServiceSpec::UserRecord)
        expect(user.id).to_not be_nil
        expect(user.first_name).to eq("John")
        expect(user.team).to eq(team)
      end
    end

    context "with has_many association" do
      subject { ServiceSpec::TeamService.new(Verse::Auth::Context[user_context]) }

      it "creates a team with new users" do
        team_data = Verse::JsonApi::Deserializer.deserialize({
          data: {
            type: "teams",
            attributes: {
              name: "Team 1"
            },
            relationships: {
              users: {
                data: [
                  {
                    type: "users",
                    attributes: {
                      first_name: "John",
                      last_name: "Doe"
                    }
                  },
                  {
                    type: "users",
                    attributes: {
                      first_name: "Jane",
                      last_name: "Doe"
                    }
                  }
                ]
              }
            }
          }
        })

        team = subject.create(team_data)

        expect(ServiceSpec::UserRepository.data).to eq(
          [
            {
              id: 1,
              first_name: "John",
              last_name: "Doe",
              team_id: 1
            },
            {
              id: 2,
              first_name: "Jane",
              last_name: "Doe",
              team_id: 1
            }
          ]
        )

        expect(team).to be_a(ServiceSpec::TeamRecord)
        expect(team.id).to_not be_nil
        expect(team.name).to eq("Team 1")
      end

    end

  end

end