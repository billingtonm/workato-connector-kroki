# frozen_string_literal: true

# This file defines a shared context for testing Workato connectors. 
# It provides a way to load a connector and its settings from files, 
# which can be used in multiple test cases to avoid duplication.

RSpec.shared_context 'connector' do
  let(:connector) { Workato::Connector::Sdk::Connector.from_file('Kroki.rb', settings) }
  let(:settings) { Workato::Connector::Sdk::Settings.from_default_file }
end
