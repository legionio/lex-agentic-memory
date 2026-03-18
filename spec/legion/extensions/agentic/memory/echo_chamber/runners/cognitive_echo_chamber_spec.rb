# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::EchoChamber::Runners::CognitiveEchoChamber do
  let(:engine) { Legion::Extensions::Agentic::Memory::EchoChamber::Helpers::ChamberEngine.new }
  let(:runner) do
    obj = Object.new
    obj.extend(described_class)
    obj.instance_variable_set(:@default_engine, engine)
    obj
  end

  describe '#create_echo' do
    it 'returns success with echo hash' do
      result = runner.create_echo(content: 'beliefs compound', engine: engine)
      expect(result[:success]).to be true
      expect(result[:echo][:content]).to eq('beliefs compound')
    end

    it 'uses default echo_type :belief' do
      result = runner.create_echo(content: 'test', engine: engine)
      expect(result[:echo][:echo_type]).to eq(:belief)
    end

    it 'accepts custom echo_type' do
      result = runner.create_echo(content: 'test', echo_type: :assumption, engine: engine)
      expect(result[:echo][:echo_type]).to eq(:assumption)
    end

    it 'accepts custom domain' do
      result = runner.create_echo(content: 'test', domain: :politics, engine: engine)
      expect(result[:echo][:domain]).to eq(:politics)
    end

    it 'accepts source_agent' do
      result = runner.create_echo(content: 'test', source_agent: 'agent-x', engine: engine)
      expect(result[:echo][:source_agent]).to eq('agent-x')
    end

    it 'returns failure for empty content' do
      result = runner.create_echo(content: '', engine: engine)
      expect(result[:success]).to be false
      expect(result[:error]).not_to be_empty
    end

    it 'returns failure for blank content' do
      result = runner.create_echo(content: '   ', engine: engine)
      expect(result[:success]).to be false
    end
  end

  describe '#create_chamber' do
    it 'returns success with chamber hash' do
      result = runner.create_chamber(label: 'ideology', engine: engine)
      expect(result[:success]).to be true
      expect(result[:chamber][:label]).to eq('ideology')
    end

    it 'accepts custom domain' do
      result = runner.create_chamber(label: 'test', domain: :science, engine: engine)
      expect(result[:chamber][:domain]).to eq(:science)
    end

    it 'accepts custom wall_thickness' do
      result = runner.create_chamber(label: 'test', wall_thickness: 0.9, engine: engine)
      expect(result[:chamber][:wall_thickness]).to eq(0.9)
    end

    it 'returns failure for empty label' do
      result = runner.create_chamber(label: '', engine: engine)
      expect(result[:success]).to be false
    end

    it 'returns failure for blank label' do
      result = runner.create_chamber(label: '  ', engine: engine)
      expect(result[:success]).to be false
    end
  end

  describe '#amplify' do
    it 'returns success for existing echo' do
      echo   = engine.create_echo(content: 'test', amplitude: 0.5)
      result = runner.amplify(echo_id: echo.id, engine: engine)
      expect(result[:success]).to be true
    end

    it 'increases amplitude' do
      echo   = engine.create_echo(content: 'test', amplitude: 0.5)
      result = runner.amplify(echo_id: echo.id, engine: engine)
      expect(result[:echo][:amplitude]).to be > 0.5
    end

    it 'returns failure for missing echo' do
      result = runner.amplify(echo_id: 'nonexistent', engine: engine)
      expect(result[:success]).to be false
      expect(result[:error]).to eq('echo not found')
    end

    it 'accepts custom rate' do
      echo   = engine.create_echo(content: 'test', amplitude: 0.5)
      result = runner.amplify(echo_id: echo.id, rate: 0.2, engine: engine)
      expect(result[:echo][:amplitude]).to be_within(0.001).of(0.7)
    end
  end

  describe '#disrupt' do
    it 'returns result from engine' do
      chamber = engine.create_chamber(label: 'test', wall_thickness: 0.3)
      result  = runner.disrupt(chamber_id: chamber.id, force: 0.8, engine: engine)
      expect(result).to have_key(:success)
    end

    it 'succeeds with sufficient force' do
      chamber = engine.create_chamber(label: 'test', wall_thickness: 0.3)
      result  = runner.disrupt(chamber_id: chamber.id, force: 0.8, engine: engine)
      expect(result[:success]).to be true
    end

    it 'fails with insufficient force' do
      chamber = engine.create_chamber(label: 'test', wall_thickness: 0.8)
      result  = runner.disrupt(chamber_id: chamber.id, force: 0.2, engine: engine)
      expect(result[:success]).to be false
    end
  end

  describe '#list_echoes' do
    before do
      engine.create_echo(content: 'bias 1', echo_type: :bias, domain: :science)
      engine.create_echo(content: 'belief 1', echo_type: :belief, domain: :politics)
      engine.create_echo(content: 'belief 2', echo_type: :belief, domain: :science)
    end

    it 'returns all active echoes with no filter' do
      result = runner.list_echoes(engine: engine)
      expect(result[:success]).to be true
      expect(result[:count]).to eq(3)
    end

    it 'filters by echo_type' do
      result = runner.list_echoes(echo_type: :belief, engine: engine)
      expect(result[:count]).to eq(2)
    end

    it 'filters by domain' do
      result = runner.list_echoes(domain: :science, engine: engine)
      expect(result[:count]).to eq(2)
    end

    it 'filters by both echo_type and domain' do
      result = runner.list_echoes(echo_type: :belief, domain: :science, engine: engine)
      expect(result[:count]).to eq(1)
    end

    it 'returns echo hashes in result' do
      result = runner.list_echoes(engine: engine)
      expect(result[:echoes].first).to have_key(:id)
    end
  end

  describe '#chamber_status' do
    it 'returns success' do
      result = runner.chamber_status(engine: engine)
      expect(result[:success]).to be true
    end

    it 'includes echo report fields' do
      result = runner.chamber_status(engine: engine)
      expect(result).to include(
        :total_echoes, :active_echoes, :resonating_echoes,
        :total_chambers, :sealed_chambers, :porous_chambers
      )
    end

    it 'reflects created echoes' do
      engine.create_echo(content: 'test')
      result = runner.chamber_status(engine: engine)
      expect(result[:total_echoes]).to eq(1)
    end

    it 'reflects created chambers' do
      engine.create_chamber(label: 'test')
      result = runner.chamber_status(engine: engine)
      expect(result[:total_chambers]).to eq(1)
    end
  end
end
