# frozen_string_literal: true

# This file defines a shared context for testing Workato connectors. 
# It defines the connector that will be tested against.
# Ensure the connector file name matches the one used in the spec files (e.g., 'Kroki.rb' in this case).

RSpec.shared_context 'connector' do
  let(:connector) { Workato::Connector::Sdk::Connector.from_file('Kroki.rb', settings) }
  let(:settings) { Workato::Connector::Sdk::Settings.from_default_file }
end
