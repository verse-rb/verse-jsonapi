RSpec.describe Verse::JsonApi::Struct do
  subject { Verse::JsonApi::Struct }

  it "can be initialized with a hash" do
    struct = subject.new(name: "John", age: 30)
    expect(struct.name).to eq("John")
    expect(struct.age).to eq(30)
  end

  it "can be initialized with a block" do
    struct = subject.new do
      def name
        "John"
      end
    end

    expect(struct.name).to eq("John")
  end

  it "can be converted to a hash" do
    struct = subject.new(name: "John", age: 30)
    expect(struct.to_h).to eq(data: {name: "John", age: 30})
  end

  it "convert complex case in hash" do
    struct = subject.new(
      id: 1,
      type: "people",
      attributes: {
        name: "John",
        age: 30,
      },
      relationships: {
        addresses: [
          subject.new( {attributes: { street: "123 Main St", city: "New York" }} )
        ]
      }
    )
    expect(struct.to_h).to eq(
      data: {
        id: 1,
        type: "people",
        attributes: { name: "John", age: 30 },
        relationships: {
          addresses: {
            data: [
              attributes: {
                street: "123 Main St", city: "New York"
              }
            ]
          }
        }
      }
    )
  end

  it "#hash" do
    struct = subject.new(name: "John", age: 30)
    expect(struct.hash).to eq({name: "John", age: 30}.hash)
  end

  it "#==" do
    struct = subject.new(name: "John", age: 30)
    expect(struct).to eq(subject.new(name: "John", age: 30))
  end

end