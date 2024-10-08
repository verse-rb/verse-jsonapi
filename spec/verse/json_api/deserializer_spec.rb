# frozen_string_literal: true

RSpec.describe Verse::JsonApi::Deserializer do
  describe "deserialize json api content" do
    context "valid documents" do
      subject { Verse::JsonApi::Deserializer }

      let(:examples) {
        [
          {
            source: "articles.json",
            expected: ->(data, _) {
              expect(data.class).to eq(Verse::JsonApi::Struct)
              expect(data.array?).to be(true)
              expect(data.data.class).to eq(Array)

              first = data.data.first
              # check that attributes are valid.
              expect(first.type).to eq("articles")
              expect(first.id).to eq("1")
              expect(first.title).to eq("JSON:API paints my bikeshed!")
              # check relationships
              expect(first.author.gender).to eq("male")
            }
          }, {
            # test with mono-object
            source: "article.json",
            expected: ->(data, _) {
              expect(data.class).to eq(Verse::JsonApi::Struct)
              expect(data.type).to eq("articles")
              expect(data.body).to eq("The shortest article. Ever.")
            }
          }, {
            # test with non-included object
            source: "article_with_non_included_author.json",
            expected: ->(data, _) {
              expect(data.class).to eq(Verse::JsonApi::Struct)
              expect(data.type).to eq("articles")
              expect(data.body).to eq("The shortest article. Ever.")

              # check relationships
              expect(data.author.id).to eq("42")
            }
          }, {
            # test with paginated data
            source: "paginated_data.json",
            expected: ->(data, _) {
              expect(data.class).to eq(Verse::JsonApi::Struct)
              first = data.data.first
              # check that attributes are valid.
              expect(first.type).to eq("articles")
            }
          }, {
            source: "metadata.json",
            expected: ->(data, _) {
              expect(data.class).to eq(Verse::JsonApi::Struct)
              expect(data.meta).to eq({ a: 1, b: true })
            }
          }
        ]
      }

      it "deserializes json:api objects" do
        examples.each do |example|
          json = JSON.parse(
            File.read(
              File.join(__dir__, "data", example[:source])
            ),
            symbolize_names: true
          )

          example[:expected].call(
            subject.deserialize(json),
            json
          )
        end
      end

      it "idempotence check" do
        example = %<{"data":{"type":"falseclass","attributes":{"active":false}}}>

        expect(
          subject.deserialize(example)
        ).to eq(
          subject.deserialize(
            subject.deserialize(example)
          )
        )
      end

      it "raises error on bad format" do
        example = { a: 1, b: 2 }.to_json
        expect{ subject.deserialize(example) }.to raise_error(Verse::JsonApi::BadFormatError)
      end
    end
  end
end
