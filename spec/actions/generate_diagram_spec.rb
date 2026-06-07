# frozen_string_literal: true

require_relative '../wisco/shared_examples'

RSpec.describe 'actions/generate_diagram', :vcr do
  it_behaves_like 'a standard action', 'generate_diagram'
end
