# frozen_string_literal: true

RSpec.describe Verse::JsonApi::Util do
  let(:record_class) do
    Class.new(Verse::Model::Record::Base) do
      field :id, primary: true, type: String

      field :name, type: String

      field(:age, type: Integer, meta: { description: "The age of the person" })

      field :secret, type: String, visible: false
    end
  end

  subject{ described_class }

  describe "#jsonapi_record" do
    it "returns a schema for a record" do
      schema = subject.jsonapi_record(record_class)

      result = schema.validate({
                                 data: {
                                   type: "people",
                                   id: "1",
                                   attributes: {
                                     name: "John",
                                     age: 30
                                   }
                                 }
                               })

      expect(result).to be_success
    end
  end

  describe "#jsonapi_collection" do
    it "returns a schema for a collection" do
      schema = subject.jsonapi_collection(record_class)

      result = schema.validate({
                                 data: [
                                   {
                                     type: "people",
                                     id: "1",
                                     attributes: {
                                       name: "John",
                                       age: 30
                                     }
                                   }
                                 ]
                               })

      expect(result).to be_success
    end
  end
end
