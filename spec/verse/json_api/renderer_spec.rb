# frozen_string_literal: true

require "spec_helper"
require_relative "data/spec_data"

RSpec.describe Verse::JsonApi::Renderer do
  let(:server) {
    server = double("server")
    allow(server).to receive(:content_type)
    expect(server).to receive(:content_type).with("application/vnd.api+json")
    allow(server).to receive(:status)

    response_mock = double("response")
    allow(response_mock).to receive(:status=)
    allow(response_mock).to receive(:status)
    allow(server).to receive(:response).and_return(response_mock)

    server
  }

  context "render object" do
    it "renders a model" do
      model = UserRecord.new({ id: 1, name: "John", age: 21 })

      output = subject.render(model, server)
      expect(JSON.parse(output, symbolize_names: true)).to eq(
        {
          data: {
            type: "users",
            id: "1",
            attributes: { name: "John", age: 21 },
          }
        }
      )
    end

    it "renders a model with belongs_to relationships" do
      model = PostRecord.new({ id: 1, title: "Post 1", content: "Lorem", user_id: 2, category_name: "tech" })

      output = subject.render(model, server)
      expect(JSON.parse(output, symbolize_names: true)).to eq(
        {
          data: {
            type: "posts",
            id: "1",
            attributes: { title: "Post 1", content: "Lorem" },
            relationships: {
              user: {
                data: {
                  type: "users",
                  id: "2"
                }
              },
              category: {
                data: {
                  type: "categories",
                  id: "tech"
                }
              }
            }
          }
        }
      )
    end

    it "renders a model with included models" do
      set = Verse::Model::IncludeSet.new([:posts])

      set.set_lookup_method([UserRecord, "posts"]) do |user|
        user.id.to_s
      end

      posts_collection = [
        PostRecord.new({ id: 1, title: "Post 1", content: "Lorem", secret_field: "Very secret" }),
        PostRecord.new({ id: 2, title: "Post 2", content: "Ipsum", secret_field: "Very secret" }),
        PostRecord.new({ id: 3, title: "Post 3", content: "Si dolorem", secret_field: "Very secret" })
      ]

      set.add_collection([UserRecord, "posts"], "1", posts_collection)
      model = UserRecord.new({ id: 1, name: "John", age: 21 }, include_set: set)

      output = subject.render(model, server)

      expect(JSON.parse(output, symbolize_names: true)).to eq(
        {
          data: {
            type: "users",
            id: "1",
            attributes: { name: "John", age: 21 },
            relationships: {
              posts: { data: [
                { type: "posts", id: "1" },
                { type: "posts", id: "2" },
                { type: "posts", id: "3" }
              ] },
            }
          },
          included: [
            {
              type: "posts",
              id: "1",
              attributes: {
                title: "Post 1",
                content: "Lorem"
              }
            },
            {
              type: "posts",
              id: "2",
              attributes: {
                title: "Post 2",
                content: "Ipsum"
              }
            },
            {
              type: "posts",
              id: "3",
              attributes: {
                title: "Post 3",
                content: "Si dolorem"
              }
            }
          ]
        }
      )
    end

    it "renders only requested fields" do
      set = Verse::Model::IncludeSet.new([:posts])

      set.set_lookup_method([UserRecord, "posts"]) do |user|
        user.id.to_s
      end

      posts_collection = [
        PostRecord.new({ id: 1, title: "Post 1", content: "Lorem", secret_field: "Very secret" }),
        PostRecord.new({ id: 2, title: "Post 2", content: "Ipsum", secret_field: "Very secret" }),
        PostRecord.new({ id: 3, title: "Post 3", content: "Si dolorem", secret_field: "Very secret" })
      ]

      set.add_collection([UserRecord, "posts"], "1", posts_collection)
      model = UserRecord.new({ id: 1, name: "John" }, include_set: set)

      subject.fields = { users: [], posts: [:title] }

      output = subject.render(model, server)

      expect(JSON.parse(output, symbolize_names: true)).to eq(
        {
          data: {
            type: "users",
            id: "1",
            attributes: {},
            relationships: {
              posts: { data: [
                { type: "posts", id: "1" },
                { type: "posts", id: "2" },
                { type: "posts", id: "3" }
              ] },
            }
          },
          included: [
            {
              type: "posts",
              id: "1",
              attributes: {
                title: "Post 1"
              }
            },
            {
              type: "posts",
              id: "2",
              attributes: {
                title: "Post 2"
              }
            },
            {
              type: "posts",
              id: "3",
              attributes: {
                title: "Post 3"
              }
            }
          ]
        }
      )
    end

    it "renders a collection" do
      collection = [
        UserRecord.new({ id: 1, name: "John", age: 20 }),
        UserRecord.new({ id: 2, name: "Jane", age: 21 })
      ]

      output = subject.render(collection, server)
      expect(JSON.parse(output, symbolize_names: true)).to eq(
        {
          data: [
            {
              type: "users",
              id: "1",
              attributes: { name: "John", age: 20 }
            },
            {
              type: "users",
              id: "2",
              attributes: { name: "Jane", age: 21 }
            }
          ]
        }
      )
    end

    it "renders an empty collection (array with metadata)" do
      collection = Verse::Util::ArrayWithMetadata.new([])

      output = subject.render(collection, server)
      expect(JSON.parse(output, symbolize_names: true)).to eq(
        {
          data: [],
          meta: {}
        }
      )
    end

    it "renders a collection (array with metadata)" do
      collection = Verse::Util::ArrayWithMetadata.new(
        [
          UserRecord.new({ id: 1, name: "John", age: 21 }),
          UserRecord.new({ id: 2, name: "Jane", age: 20 })
        ], metadata: { total: 2 }
      )

      output = subject.render(collection, server)
      expect(JSON.parse(output, symbolize_names: true)).to eq(
        {
          data: [
            {
              type: "users",
              id: "1",
              attributes: { name: "John", age: 21 },
            },
            {
              type: "users",
              id: "2",
              attributes: { name: "Jane", age: 20 },
            }
          ],
          meta: { total: 2 }
        }
      )
    end
  end

  context "render custom object" do
    it "renders a hash" do
      output = subject.render({ test: "test" }, server)
      expect(JSON.parse(output, symbolize_names: true)).to eq(
        {
          data: {
            test: "test"
          }
        }
      )
    end
  end

  context "render object with custom primary key" do
    it "renders a model" do
      model = CategoryRecord.new({ name: "test" })

      output = subject.render(model, server)
      expect(JSON.parse(output, symbolize_names: true)).to eq(
        {
          data: {
            type: "categories",
            id: "test",
            attributes: {
              name: "test"
            }
          }
        }
      )
    end
  end

  context "render error" do
    context "verse error" do
      it "renders an error" do
        error = Verse::Error::Base.new("test")

        output = subject.render(error, server)
        expect(JSON.parse(output, symbolize_names: true)).to eq(
          {
            errors: [
              {
                status: "500",
                title: "Verse::Error::Base",
                detail: "test"
              }
            ],
            meta: {
              backtrace: error.backtrace
            }
          }
        )
      end
    end

    context "other errors" do
      it "renders an error" do
        error = StandardError.new("test")

        output = subject.render(error, server)
        expect(JSON.parse(output, symbolize_names: true)).to eq(
          {
            errors: [
              {
                detail: "test",
                status: "500",
                title: "StandardError",
              }
            ],
            meta: {
              backtrace: error.backtrace
            }
          }
        )
      end
    end
  end
end
