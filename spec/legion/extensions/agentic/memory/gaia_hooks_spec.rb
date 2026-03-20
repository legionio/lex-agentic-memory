# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'GAIA snapshot hooks' do
  it 'entry point has snapshot lifecycle hooks block' do
    entry_point = File.read(
      File.expand_path('../../../../../lib/legion/extensions/agentic/memory.rb', __dir__)
    )
    expect(entry_point).to include('service.shutting_down')
    expect(entry_point).to include('gaia.started')
    expect(entry_point).to include('Trace::Helpers::Snapshot')
  end
end
