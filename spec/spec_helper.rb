# frozen_string_literal: true

require 'bundler/setup'
require 'ruboty/ai_agent'
require 'webmock/rspec'

# Load factory methods and mock helpers
require_relative 'support/factories'
require_relative 'support/mocks'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

WebMock.disable_net_connect!
