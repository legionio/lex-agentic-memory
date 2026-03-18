# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::Echo::Runners::CognitiveEcho do
  let(:engine) { Legion::Extensions::Agentic::Memory::Echo::Helpers::EchoEngine.new }
  let(:runner) do
    obj = Object.new
    obj.extend(described_class)
    obj.instance_variable_set(:@default_engine, engine)
    obj
  end

  describe '#create_echo' do
    it 'returns success with echo hash' do
      result = runner.create_echo(content: 'test', engine: engine)
      expect(result[:success]).to be true
      expect(result[:echo][:content]).to eq('test')
    end
  end

  describe '#reinforce_echo' do
    it 'returns success for known echo' do
      echo = engine.create_echo(content: 'test', intensity: 0.5)
      result = runner.reinforce_echo(echo_id: echo.id, engine: engine)
      expect(result[:success]).to be true
    end

    it 'returns failure for unknown echo' do
      result = runner.reinforce_echo(echo_id: 'bad', engine: engine)
      expect(result[:success]).to be false
    end
  end

  describe '#decay_all' do
    it 'returns success' do
      result = runner.decay_all(engine: engine)
      expect(result[:success]).to be true
    end
  end

  describe '#active_echoes' do
    it 'returns active list' do
      engine.create_echo(content: 'test')
      result = runner.active_echoes(engine: engine)
      expect(result[:count]).to eq(1)
    end
  end

  describe '#priming_echoes' do
    it 'returns priming list' do
      engine.create_echo(content: 'test', intensity: 0.5)
      result = runner.priming_echoes(engine: engine)
      expect(result[:count]).to eq(1)
    end
  end

  describe '#echoes_by_domain' do
    it 'filters by domain' do
      engine.create_echo(content: 'a', domain: :security)
      result = runner.echoes_by_domain(domain: :security, engine: engine)
      expect(result[:count]).to eq(1)
    end
  end

  describe '#priming_effect' do
    it 'returns effect and label' do
      engine.create_echo(content: 'test', domain: :security, intensity: 0.5)
      result = runner.priming_effect(domain: :security, engine: engine)
      expect(result[:success]).to be true
      expect(result[:priming_effect]).to be > 0.0
    end
  end

  describe '#echo_status' do
    it 'returns comprehensive status' do
      result = runner.echo_status(engine: engine)
      expect(result[:success]).to be true
      expect(result).to include(:total_echoes, :echo_chamber_score)
    end
  end
end
