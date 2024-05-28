# frozen_string_literal: true

RSpec.describe Verse::JsonApi::Deserializer do
  describe "deserialize json api content" do
    context "valid documents" do
      subject { Verse::JsonApi::Deserializer }

      let(:examples) {
        [
          {
            source: %<{"data":[{"type":"articles","id":"1","attributes":{"title":"JSON:API paints my bikeshed!","body":"The shortest article. Ever.","created":"2015-05-22T14:56:29.000Z","updated":"2015-05-22T14:56:28.000Z"},"relationships":{"author":{"data":{"id":"42","type":"people"}}}}],"included":[{"type":"people","id":"42","attributes":{"name":"John","age":80,"gender":"male"}}]}>,
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
            source: %<{"data":{"type":"articles","id":"3","attributes":{"title":"JSON:API paints my bikeshed!","body":"The shortest article. Ever.","created":"2015-05-22T14:56:29.000Z","updated":"2015-05-22T14:56:28.000Z"}}}>,
            expected: ->(data, _) {
              expect(data.class).to eq(Verse::JsonApi::Struct)
              expect(data.type).to eq("articles")
              expect(data.body).to eq("The shortest article. Ever.")
            }
          }, {
            # test with non-included object
            source: %<{"data":{"type":"articles","id":"3","attributes":{"title":"JSON:API paints my bikeshed!","body":"The shortest article. Ever.","created":"2015-05-22T14:56:29.000Z","updated":"2015-05-22T14:56:28.000Z"},"relationships":{"author":{"data":{"id":"42","type":"people"}}}}}>,
            expected: ->(data, _) {
              expect(data.class).to eq(Verse::JsonApi::Struct)
              expect(data.type).to eq("articles")
              expect(data.body).to eq("The shortest article. Ever.")

              # check relationships
              expect(data.author.id).to eq("42")
            }
          }, {
            # test with paginated data
            source: %<{"meta":{"totalPages":13},"data":[{"type":"articles","id":"3","attributes":{"title":"JSON:API paints my bikeshed!","body":"The shortest article. Ever.","created":"2015-05-22T14:56:29.000Z","updated":"2015-05-22T14:56:28.000Z"}}],"links":{"self":"http://example.com/articles?page[number]=3&page[size]=1","first":"http://example.com/articles?page[number]=1&page[size]=1","prev":"http://example.com/articles?page[number]=2&page[size]=1","next":"http://example.com/articles?page[number]=4&page[size]=1","last":"http://example.com/articles?page[number]=13&page[size]=1"}}>,
            expected: ->(data, _) {
              expect(data.class).to eq(Verse::JsonApi::Struct)
              first = data.data.first
              # check that attributes are valid.
              expect(first.type).to eq("articles")
            }
          },
          {
            source: %<{"data":{"type":"falseclass","attributes":{"active":false}}}>,
            expected: ->(data, _) {
              expect(data.active).to eq(false)
            }
          }
        ]
      }

      it "deserializes json:api objects" do
        examples.each do |example|
          json = JSON.parse(example[:source], symbolize_names: true)
          example[:expected].call(
            subject.deserialize(json),
            json
          )
        end
      end

      it "idempotence" do
        example =  %<{"data":{"type":"falseclass","attributes":{"active":false}}}>

        expect(subject.deserialize(example)).to eq(subject.deserialize(subject.deserialize(example)))
      end

      it "metadata" do
        example =  %<{"data":{"type":"falseclass","attributes":{"active":false}}, "meta": {"a": 1, "b": true}}>
        output = subject.deserialize(example)
        expect(output.meta).to eq({ a: 1, b: true })
      end

      it "raises error on bad format" do
        example = { a: 1, b: 2 }.to_json
        expect{ subject.deserialize(example) }.to raise_error(Verse::JsonApi::BadFormatError)
      end
    end
  end
end
