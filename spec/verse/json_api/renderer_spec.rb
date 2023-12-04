require "spec_helper"
require_relative "./spec_data"

RSpec.describe Verse::JsonApi::Renderer do
  context "render object" do
    it "renders a model" do
      model = UserRecord.new({ id: 1, name: "John" })

      output = subject.render(model)
      expect(output).to eq({
        data: {
          type: "users",
          id: "1",
          attributes: { name: "John" },
        }
      })
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
      model = UserRecord.new({ id: 1, name: "John" }, include_set: set)

      output = subject.render(model)

      expect(output).to eq({
        data: {
          type: "users",
          id: "1",
          attributes: { name: "John" },
          relationships: {
            posts: { data: [
              { type: "posts", id: "1" },
              { type: "posts", id: "2" },
              { type: "posts", id: "3" }
              ]
            },
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
      })

    end

    it "renders a collection" do
      collection = [
        UserRecord.new({ id: 1, name: "John" }),
        UserRecord.new({ id: 2, name: "Jane" })
      ]

      output = subject.render(collection)
      expect(output).to eq({
        data: [
          {
            type: "users",
            id: "1",
            attributes: { name: "John" }
          },
          {
            type: "users",
            id: "2",
            attributes: { name: "Jane" }
          }
        ]
      })
    end

    it "renders a collection (array with metadata)" do
      collection = Verse::Util::ArrayWithMetadata.new([
        UserRecord.new({ id: 1, name: "John" }),
        UserRecord.new({ id: 2, name: "Jane" })
      ], { total: 2 })

      output = subject.render(collection)
      expect(output).to eq({
        data: [
          {
            type: "users",
            id: "1",
            attributes: { name: "John" },
            relationships: {
              posts: { data: [] },
              comments: { data: [] },
              account: { data: nil }
            }
          },
          {
            type: "users",
            id: "2",
            attributes: { name: "Jane" },
            relationships: {
              posts: { data: [] },
              comments: { data: [] },
              account: { data: nil }
            }
          }
        ],
        included: [],
        meta: { total: 2 }
      })
    end
  end

  context "render error" do
    context "verse error" do
      it "renders an error" do
        error = Verse::Error::Base.new("test")

        output = subject.render(error)
        expect(output).to eq({
          errors: [
            {
              status: "500",
              code: "500",
              title: "Internal Server Error",
              detail: "test"
            }
          ]
        })
      end
    end

    context "other errors" do
      it "renders an error" do
        error = StandardError.new("test")

        output = subject.render(error)
        expect(output).to eq({
          errors: [
            {
              status: "500",
              code: "500",
              title: "Internal Server Error",
              detail: "test"
            }
          ]
        })
      end
    end
  end
end