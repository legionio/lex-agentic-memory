# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Echo::Helpers::EchoEngine do
  subject(:engine) { described_class.new }

  describe '#create_echo' do
    it 'creates and stores an echo' do
      echo = engine.create_echo(content: 'test thought')
      expect(echo.content).to eq('test thought')
    end
  end

  describe '#reinforce_echo' do
    it 'increases echo intensity' do
      echo = engine.create_echo(content: 'test', intensity: 0.5)
      engine.reinforce_echo(echo_id: echo.id)
      expect(echo.intensity).to be > 0.5
    end

    it 'returns nil for unknown echo' do
      expect(engine.reinforce_echo(echo_id: 'bad')).to be_nil
    end
  end

  describe '#decay_all!' do
    it 'decays all echoes' do
      echo = engine.create_echo(content: 'test')
      original = echo.intensity
      engine.decay_all!
      expect(echo.intensity).to be < original
    end
  end

  describe '#active_echoes' do
    it 'returns non-silent echoes' do
      engine.create_echo(content: 'active', intensity: 0.5)
      engine.create_echo(content: 'silent', intensity: 0.01)
      expect(engine.active_echoes.size).to eq(1)
    end
  end

  describe '#priming_echoes' do
    it 'returns echoes above priming threshold' do
      engine.create_echo(content: 'strong', intensity: 0.5)
      engine.create_echo(content: 'weak', intensity: 0.1)
      expect(engine.priming_echoes.size).to eq(1)
    end
  end

  describe '#interfering_echoes' do
    it 'returns echoes above interference threshold' do
      engine.create_echo(content: 'loud', intensity: 0.6)
      engine.create_echo(content: 'quiet', intensity: 0.2)
      expect(engine.interfering_echoes.size).to eq(1)
    end
  end

  describe '#echoes_by_domain' do
    it 'filters by domain' do
      engine.create_echo(content: 'a', domain: :security)
      engine.create_echo(content: 'b', domain: :memory)
      expect(engine.echoes_by_domain(domain: :security).size).to eq(1)
    end
  end

  describe '#echoes_by_type' do
    it 'filters by type' do
      engine.create_echo(content: 'a', echo_type: :emotion)
      engine.create_echo(content: 'b', echo_type: :decision)
      expect(engine.echoes_by_type(echo_type: :emotion).size).to eq(1)
    end
  end

  describe '#strongest_echoes' do
    it 'returns sorted by intensity descending' do
      engine.create_echo(content: 'weak', intensity: 0.3)
      strong = engine.create_echo(content: 'strong', intensity: 0.9)
      expect(engine.strongest_echoes(limit: 1).first.id).to eq(strong.id)
    end
  end

  describe '#echo_chamber_score' do
    it 'returns 0.0 with no echoes' do
      expect(engine.echo_chamber_score).to eq(0.0)
    end

    it 'returns 1.0 when all echoes in one domain' do
      engine.create_echo(content: 'a', domain: :security)
      engine.create_echo(content: 'b', domain: :security)
      expect(engine.echo_chamber_score).to eq(1.0)
    end

    it 'returns lower score with diverse domains' do
      engine.create_echo(content: 'a', domain: :security, intensity: 0.5)
      engine.create_echo(content: 'b', domain: :memory, intensity: 0.5)
      expect(engine.echo_chamber_score).to eq(0.5)
    end
  end

  describe '#priming_effect_for' do
    it 'returns 0.0 for domain with no priming echoes' do
      expect(engine.priming_effect_for(domain: :security)).to eq(0.0)
    end

    it 'returns accumulated priming from matching domain' do
      engine.create_echo(content: 'sec1', domain: :security, intensity: 0.5)
      expect(engine.priming_effect_for(domain: :security)).to be > 0.0
    end
  end

  describe '#interference_level' do
    it 'returns 0.0 with no interfering echoes' do
      engine.create_echo(content: 'x', intensity: 0.2)
      expect(engine.interference_level).to eq(0.0)
    end

    it 'returns positive when strong echoes exist' do
      engine.create_echo(content: 'x', intensity: 0.8)
      expect(engine.interference_level).to be > 0.0
    end
  end

  describe '#average_intensity' do
    it 'returns 0.0 with no echoes' do
      expect(engine.average_intensity).to eq(0.0)
    end

    it 'computes average' do
      engine.create_echo(content: 'a', intensity: 0.4)
      engine.create_echo(content: 'b', intensity: 0.6)
      expect(engine.average_intensity).to eq(0.5)
    end
  end

  describe '#echo_report' do
    it 'includes key report fields' do
      report = engine.echo_report
      expect(report).to include(
        :total_echoes, :active_count, :priming_count, :interfering_count,
        :average_intensity, :echo_chamber_score, :chamber_label,
        :interference_level, :strongest
      )
    end
  end

  describe '#to_h' do
    it 'includes summary' do
      hash = engine.to_h
      expect(hash).to include(:total_echoes, :active, :average_intensity, :chamber_score)
    end
  end
end
