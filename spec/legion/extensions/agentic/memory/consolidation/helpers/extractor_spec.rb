# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Consolidation::Helpers::Extractor do
  it 'extracts heuristic categories from chat-like messages' do
    summary = described_class.extract([
                                        { content: 'We went with SQLite because it is local.' },
                                        { content: 'Never send embeddings to vLLM.' },
                                        { content: 'The failing query was fixed after adding partition_id.' },
                                        { content: 'Found the association load root cause.' }
                                      ])

    expect(summary[:decisions]).to include('We went with SQLite because it is local.')
    expect(summary[:preferences]).to include('Never send embeddings to vLLM.')
    expect(summary[:milestones]).to include('The failing query was fixed after adding partition_id.')
    expect(summary[:problems]).to include('The failing query was fixed after adding partition_id.')
    expect(summary[:discoveries]).to include('Found the association load root cause.')
  end
end
