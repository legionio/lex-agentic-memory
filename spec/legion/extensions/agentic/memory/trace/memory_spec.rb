# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Trace do
  it 'has a version number' do
    expect(Legion::Extensions::Agentic::Memory::Trace::VERSION).not_to be_nil
  end

  it 'has a version that is a string' do
    expect(Legion::Extensions::Agentic::Memory::Trace::VERSION).to be_a(String)
  end
end
