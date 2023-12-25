require "spec_helper"
require_relative "./spec_data"

RSpec.describe Verse::JsonApi::ExpositionDsl, type: :exposition do
  before do
    Verse.on_boot {
      require_relative "./test_exposition"
      TestExposition.register
    }

    Verse.start(
      :test,
      config_path: File.join(__dir__, "config.yml")
    )
  end

  context "#create" do
    it "allows creation with good input", as: :user do

      expect_any_instance_of(TestService).to receive(:create){ |obj, struct|
        expect(struct.name).to eq("John")
        expect(struct.type).to eq("users")
      }.and_return(UserRecord.new({id: 1, name: "John"}))

      post "/users/", {
        data: {
          type: "users",
          attributes: { name: "John" }
        }
      }

      expect(last_response.status).to eq(201)
      expect(JSON.parse(last_response.body, symbolize_names: true)).to eq(
        {
          data: {
            id: "1",
            type: "users",
            attributes: { name: "John" }
          }
        }
      )
    end

  end

end