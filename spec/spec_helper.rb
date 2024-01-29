# frozen_string_literal: true
require "bootsnap"
Bootsnap.setup(cache_dir: "tmp/cache")

require "simplecov"
SimpleCov.start do
  add_filter do |file|
    file.filename !~ /lib/
  end
end

require "pry"
require "bundler"

Bundler.require

require "verse/json_api"
require "verse/http/spec"


def silent
  return unless (logger = Verse.logger)

  level = logger.level
  logger.fatal!

  yield
ensure
  logger.level = level
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Add user fixture
  Verse::Http::Spec::HttpHelper.add_user("user", :user)

  # set a dummy role for testing
  Verse::Auth::Context[:user] = %w[
    users.read.*
    users.write.*
    verse-http:foo.*.*
  ]

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
