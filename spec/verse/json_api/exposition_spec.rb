# frozen_string_literal: true

require "spec_helper"
require_relative "data/spec_data"

RSpec.describe Verse::JsonApi::ExpositionDsl, type: :exposition do
  before do
    Verse.on_boot {
      require_relative "data/test_exposition"
      TestExposition.register
    }

    Verse.start(
      :test,
      config_path: File.join(__dir__, "data/config.yml")
    )
  end

  after do
    Verse.stop
  end

  context "#create" do
    it "allows creation with good input", as: :user do
      expect_any_instance_of(TestService).to receive(:create){ |_obj, attr|
        expect(attr.name).to eq("John")
      }.and_return(UserRecord.new({ id: 1, name: "John", age: 20 }))

      post "/users", {
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
            attributes: { name: "John", age: 20 }
          }
        }
      )

      # We created a special body in the test set, let see if it triggers:
      expect(TestExposition.trigger).to eq(true)
    end
  end

  context "#delete" do
    it "allows deletion with good input", as: :user do
      expect_any_instance_of(TestService).to receive(:delete){ |_obj, id|
        expect(id).to eq(1)
      }

      delete "/users/1"

      expect(last_response.status).to eq(204)
    end
  end

  context "#index", as: :user do
    it "allows index" do
      expect_any_instance_of(TestService).to receive(:index){ |_obj, filters, included:, page:, items_per_page:, sort:, query_count:|
        expect(filters).to eq({})
        expect(included).to eq([])
        expect(page).to eq(1)
        expect(items_per_page).to eq(1000)
        expect(sort).to eq(nil)
        expect(query_count).to eq(false)
      }.and_return([UserRecord.new({ id: 1, name: "John", age: 19 })])

      get "/users"

      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body, symbolize_names: true)).to eq(
        {
          data: [
            {
              id: "1",
              type: "users",
              attributes: { name: "John", age: 19 }
            }
          ]
        }
      )
    end

    it "filters the attribues" do
      expect_any_instance_of(TestService).to receive(:index){ |_obj, filters, included:, page:, items_per_page:, sort:, query_count:|
        expect(filters).to eq({})
        expect(included).to eq([])
        expect(page).to eq(1)
        expect(items_per_page).to eq(1000)
        expect(sort).to eq(nil)
        expect(query_count).to eq(false)
      }.and_return([UserRecord.new({ id: 1, name: "John", age: 19 })])

      get "/users?fields[users][]=name"

      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body, symbolize_names: true)).to eq(
        {
          data: [
            {
              id: "1",
              type: "users",
              attributes: { name: "John" }
            }
          ]
        }
      )
    end

    it "allows index with filters" do
      expect_any_instance_of(TestService).to receive(:index){ |_obj, filters, included:, page:, items_per_page:, sort:, query_count:|
        expect(filters).to eq({ name: "John" })
        expect(included).to eq([])
        expect(page).to eq(1)
        expect(items_per_page).to eq(1000)
        expect(sort).to eq(nil)
        expect(query_count).to eq(false)
      }.and_return([UserRecord.new({ id: 1, name: "John", age: 20 })])

      get "/users?filter[name]=John"

      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body, symbolize_names: true)).to eq(
        {
          data: [
            {
              id: "1",
              type: "users",
              attributes: { name: "John", age: 20 }
            }
          ]
        }
      )
    end

    it "ignores unallowed filters" do
      expect_any_instance_of(TestService).to receive(:index){ |_obj, filters, included:, page:, items_per_page:, sort:, query_count:|
        expect(filters).to eq({})
        expect(included).to eq([])
        expect(page).to eq(1)
        expect(items_per_page).to eq(1000)
        expect(sort).to eq(nil)
        expect(query_count).to eq(false)
      }.and_return([UserRecord.new({ id: 1, name: "John", age: 20 })])

      get "/users?filter[unallowed]=John"

      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body, symbolize_names: true)).to eq(
        {
          data: [
            {
              id: "1",
              type: "users",
              attributes: { name: "John", age: 20 }
            }
          ]
        }
      )
    end

    it "allows filter declared in allowed_filters" do
      expect_any_instance_of(TestService).to receive(:index){ |_obj, filters, included:, page:, items_per_page:, sort:, query_count:|
        expect(filters).to eq({ name__match: "John" })
        expect(included).to eq([])
        expect(page).to eq(1)
        expect(items_per_page).to eq(1000)
        expect(sort).to eq(nil)
        expect(query_count).to eq(false)
      }.and_return([UserRecord.new({ id: 1, name: "John", age: 20 })])

      get "/users?filter[name__match]=John"

      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body, symbolize_names: true)).to eq(
        {
          data: [
            {
              id: "1",
              type: "users",
              attributes: { name: "John", age: 20 }
            }
          ]
        }
      )
    end

    it "rejects if user request included resource not allowed" do
      silent do
        get "/users?included[]=comments"

        expect(last_response.status).to eq(422)
        expect(JSON.parse(last_response.body, symbolize_names: true)[:errors].first[:title]).to eq(
          "Verse::Error::ValidationFailed"
        )
      end
    end

    it "allows if user request included resource allowed" do
      expect_any_instance_of(TestService).to receive(:index){ |_obj, filters, included:, page:, items_per_page:, sort:, query_count:|
        expect(filters).to eq({})
        expect(included).to eq(["posts"])
        expect(page).to eq(1)
        expect(items_per_page).to eq(1000)
        expect(sort).to eq(nil)
        expect(query_count).to eq(false)
      }.and_return([UserRecord.new({ id: 1, name: "John", age: 20 })])

      get "/users?included[]=posts"

      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body, symbolize_names: true)).to eq(
        {
          data: [
            {
              id: "1",
              type: "users",
              attributes: { name: "John", age: 20 }
            }
          ]
        }
      )
    end
  end

  context "#show", as: :user do
    it "allows show" do
      expect_any_instance_of(TestService).to receive(:show){ |_obj, id, included:|
        expect(id).to eq(1)
        expect(included).to eq([])
      }.and_return(UserRecord.new({ id: 1, name: "John", age: 20 }))

      get "/users/1"

      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body, symbolize_names: true)).to eq(
        {
          data: {
            id: "1",
            type: "users",
            attributes: { name: "John", age: 20 }
          }
        }
      )
    end

    it "filter out the attributes" do
      expect_any_instance_of(TestService).to receive(:show){ |_obj, id, included:|
        expect(id).to eq(1)
        expect(included).to eq([])
      }.and_return(UserRecord.new({ id: 1, name: "John", age: 20 }))

      get "/users/1?fields[users][]=name"

      expect(last_response.status).to eq(200)
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

    it "disallow if included is not in the list" do
      silent do
        get "/users/1?included[]=comments"

        expect(last_response.status).to eq(422)
      end
    end

    it "allow if included is in the list" do
      expect_any_instance_of(TestService).to receive(:show){ |_obj, id, included:|
        expect(id).to eq(1)
        expect(included).to eq(["posts"])
      }.and_return(UserRecord.new({ id: 1, name: "John", age: 20 }))

      get "/users/1?included[]=posts"

      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body, symbolize_names: true)).to eq(
        {
          data: {
            id: "1",
            type: "users",
            attributes: { name: "John", age: 20 }
          }
        }
      )
    end
  end

  context "#update", as: :user do
    it "allows update" do
      expect_any_instance_of(TestService).to receive(:update){ |_obj, struct|
        expect(struct.id).to eq(1)
        expect(struct.name).to eq("John")
      }.and_return(UserRecord.new({ id: 1, name: "John", age: 20 }))

      patch "/users/1", {
        data: {
          type: "users",
          attributes: { name: "John", age: 20 }
        }
      }

      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body, symbolize_names: true)).to eq(
        {
          data: {
            id: "1",
            type: "users",
            attributes: { name: "John", age: 20 }
          }
        }
      )
    end

    it "removes illegal fields" do
      expect_any_instance_of(TestService).to receive(:update){ |_obj, struct|
        expect(struct.id).to eq(1)
        expect(struct.attributes[:name]).to eq("John")
        expect(struct.attributes[:secret_field]).to eq(nil)
      }.and_return(UserRecord.new({ id: 1, name: "John", age: 20 }))

      patch "/users/1", {
        data: {
          type: "users",
          attributes: { name: "John", secret_field: "Very secret", age: 20 }
        }
      }

      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body, symbolize_names: true)).to eq(
        {
          data: {
            id: "1",
            type: "users",
            attributes: { name: "John", age: 20 }
          }
        }
      )
    end
  end

  context "metadata" do
    it "stores metadata on exposition endpoint" do
      expect(TestExposition.exposed_endpoints[:show][:meta].meta).to eq(nodoc: true)
    end
  end

end
