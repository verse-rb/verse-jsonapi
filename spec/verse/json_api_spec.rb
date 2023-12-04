# frozen_string_literal: true

RSpec.describe Verse::JsonApi do
  it "has a version number" do
    expect(Verse::JsonApi::VERSION).not_to be nil
  end
end
