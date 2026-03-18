# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Paleontology::Helpers::Excavation do
  let(:excavation) { described_class.new(target_stratum: 2) }

  describe '#initialize' do
    it 'assigns a UUID' do
      expect(excavation.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'sets target_stratum' do
      expect(excavation.target_stratum).to eq 2
    end

    it 'starts in_progress' do
      expect(excavation.status).to eq :in_progress
    end

    it 'starts with no fossils' do
      expect(excavation.fossils_found).to be_empty
    end

    it 'clamps stratum to 0..4' do
      e = described_class.new(target_stratum: 99)
      expect(e.target_stratum).to eq 4
    end
  end

  describe '#record_find!' do
    it 'adds fossil to finds' do
      fossil = Legion::Extensions::Agentic::Memory::Paleontology::Helpers::Fossil.new(
        fossil_type: :strategy, domain: :cognitive, content: 'x',
        extinction_cause: :obsolescence
      )
      excavation.record_find!(fossil)
      expect(excavation.fossils_found.size).to eq 1
    end
  end

  describe '#complete!' do
    it 'marks as completed' do
      excavation.complete!
      expect(excavation).to be_completed
    end

    it 'returns false if already completed' do
      excavation.complete!
      expect(excavation.complete!).to be false
    end

    it 'sets completed_at' do
      excavation.complete!
      expect(excavation.completed_at).to be_a Time
    end
  end

  describe '#yield_rate' do
    it 'returns 0.0 when empty' do
      expect(excavation.yield_rate).to eq 0.0
    end
  end

  describe '#to_h' do
    it 'includes expected keys' do
      %i[id target_stratum stratum_label fossils_count yield_rate
         status started_at completed_at].each do |key|
        expect(excavation.to_h).to have_key(key)
      end
    end
  end
end
