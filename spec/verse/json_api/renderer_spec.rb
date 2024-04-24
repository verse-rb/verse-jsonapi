# frozen_string_literal: true

require "spec_helper"
require_relative "data/spec_data"

RSpec.describe Verse::JsonApi::Renderer do
  let(:ctx) {
    out = double("ctx", content_type: nil)
    expect(out).to receive(:content_type).with("application/vnd.api+json")
    allow(out).to receive(:status)

    out
  }

  context "render object" do
    it "renders a model" do
      model = UserRecord.new({ id: 1, name: "John" })

      output = subject.render(model, ctx)
      expect(JSON.parse(output, symbolize_names: true)).to eq(
        {
          data: {
            type: "users",
            id: "1",
            attributes: { name: "John" },
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
      model = UserRecord.new({ id: 1, name: "John" }, include_set: set)

      output = subject.render(model, ctx)

      expect(JSON.parse(output, symbolize_names: true)).to eq(
        {
          data: {
            type: "users",
            id: "1",
            attributes: { name: "John" },
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

    it "renders a collection" do
      collection = [
        UserRecord.new({ id: 1, name: "John" }),
        UserRecord.new({ id: 2, name: "Jane" })
      ]

      output = subject.render(collection, ctx)
      expect(JSON.parse(output, symbolize_names: true)).to eq(
        {
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
        }
      )
    end

    it "renders an empty collection (array with metadata)" do
      collection = Verse::Util::ArrayWithMetadata.new([])

      output = subject.render(collection, ctx)
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
          UserRecord.new({ id: 1, name: "John" }),
          UserRecord.new({ id: 2, name: "Jane" })
        ], metadata: { total: 2 }
      )

      output = subject.render(collection, ctx)
      expect(JSON.parse(output, symbolize_names: true)).to eq(
        {
          data: [
            {
              type: "users",
              id: "1",
              attributes: { name: "John" },
            },
            {
              type: "users",
              id: "2",
              attributes: { name: "Jane" },
            }
          ],
          meta: { total: 2 }
        }
      )
    end
  end

  context "render custom object" do
    it "renders a hash" do
      output = subject.render({ test: "test" }, ctx)
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

      output = subject.render(model, ctx)
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

        output = subject.render(error, ctx)
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

        output = subject.render(error, ctx)
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
