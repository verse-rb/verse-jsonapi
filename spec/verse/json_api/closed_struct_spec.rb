RSpec.describe Verse::JsonApi::ClosedStruct do
  subject { Verse::JsonApi::ClosedStruct }

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

  it "can be updated" do
    struct = subject.new(name: "John", age: 30)
    struct.__update(:name, "Jane")
    expect(struct.name).to eq("Jane")
  end

  it "can be converted to a hash" do
    struct = subject.new(name: "John", age: 30)
    expect(struct.to_h).to eq({name: "John", age: 30})
  end

  it "convert complex case in hash" do
    struct = subject.new(
      name: "John",
      age: 30,
      addresses: [
        subject.new(street: "123 Main St", city: "New York")
      ]
    )
    expect(struct.to_h).to eq({name: "John", age: 30, addresses: [{street: "123 Main St", city: "New York"}]})
  end

  it "#each_pair" do
    struct = subject.new(name: "John", age: 30)
    expect(struct.each_pair.to_a).to eq([[:name, "John"], [:age, 30]])
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