# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::EchoChamber::Helpers::ChamberEngine do
  subject(:engine) { described_class.new }

  describe '#create_echo' do
    it 'creates an echo with default parameters' do
      echo = engine.create_echo(content: 'test belief')
      expect(echo.content).to eq('test belief')
    end

    it 'creates an echo with custom echo_type' do
      echo = engine.create_echo(content: 'test', echo_type: :bias)
      expect(echo.echo_type).to eq(:bias)
    end

    it 'creates an echo with custom domain' do
      echo = engine.create_echo(content: 'test', domain: :science)
      expect(echo.domain).to eq(:science)
    end

    it 'creates an echo with custom source_agent' do
      echo = engine.create_echo(content: 'test', source_agent: 'agent-1')
      expect(echo.source_agent).to eq('agent-1')
    end

    it 'creates an echo with custom amplitude' do
      echo = engine.create_echo(content: 'test', amplitude: 0.8)
      expect(echo.amplitude).to eq(0.8)
    end

    it 'returns an Echo instance' do
      echo = engine.create_echo(content: 'test')
      expect(echo).to be_a(Legion::Extensions::Agentic::Memory::EchoChamber::Helpers::Echo)
    end
  end

  describe '#create_chamber' do
    it 'creates a chamber with label' do
      chamber = engine.create_chamber(label: 'ideology chamber')
      expect(chamber.label).to eq('ideology chamber')
    end

    it 'creates a chamber with custom domain' do
      chamber = engine.create_chamber(label: 'x', domain: :politics)
      expect(chamber.domain).to eq(:politics)
    end

    it 'creates a chamber with custom wall_thickness' do
      chamber = engine.create_chamber(label: 'x', wall_thickness: 0.8)
      expect(chamber.wall_thickness).to eq(0.8)
    end

    it 'returns a Chamber instance' do
      chamber = engine.create_chamber(label: 'test')
      expect(chamber).to be_a(Legion::Extensions::Agentic::Memory::EchoChamber::Helpers::Chamber)
    end
  end

  describe '#amplify_echo' do
    it 'increases echo amplitude' do
      echo = engine.create_echo(content: 'test', amplitude: 0.5)
      engine.amplify_echo(echo_id: echo.id)
      expect(echo.amplitude).to be > 0.5
    end

    it 'returns nil for unknown echo_id' do
      expect(engine.amplify_echo(echo_id: 'nonexistent')).to be_nil
    end

    it 'accepts custom rate' do
      echo = engine.create_echo(content: 'test', amplitude: 0.5)
      engine.amplify_echo(echo_id: echo.id, rate: 0.2)
      expect(echo.amplitude).to be_within(0.001).of(0.7)
    end
  end

  describe '#disrupt_chamber' do
    let(:chamber) { engine.create_chamber(label: 'test', wall_thickness: 0.4) }

    it 'returns error for unknown chamber_id' do
      result = engine.disrupt_chamber(chamber_id: 'nonexistent', force: 0.9)
      expect(result[:success]).to be false
      expect(result[:error]).to eq('chamber not found')
    end

    it 'succeeds with sufficient force' do
      result = engine.disrupt_chamber(chamber_id: chamber.id, force: 0.9)
      expect(result[:success]).to be true
    end

    it 'fails with insufficient force' do
      result = engine.disrupt_chamber(chamber_id: chamber.id, force: 0.2)
      expect(result[:success]).to be false
    end

    it 'records disruption in history on success' do
      engine.disrupt_chamber(chamber_id: chamber.id, force: 0.9)
      expect(engine.disruption_history).not_to be_empty
    end

    it 'does not record failed disruption in history' do
      engine.disrupt_chamber(chamber_id: chamber.id, force: 0.1)
      expect(engine.disruption_history).to be_empty
    end
  end

  describe '#decay_all!' do
    it 'reduces amplitude of all echoes' do
      echo = engine.create_echo(content: 'test', amplitude: 0.8)
      original = echo.amplitude
      engine.decay_all!
      expect(echo.amplitude).to be < original
    end

    it 'returns a hash with decay stats' do
      engine.create_echo(content: 'test')
      result = engine.decay_all!
      expect(result).to include(:decayed, :remaining, :pruned)
    end

    it 'prunes silent echoes after decay' do
      engine.create_echo(content: 'faint', amplitude: 0.02)
      engine.decay_all!
      expect(engine.active_echoes).to be_empty
    end
  end

  describe '#echoes_by_type' do
    it 'filters echoes by type' do
      engine.create_echo(content: 'a', echo_type: :bias)
      engine.create_echo(content: 'b', echo_type: :conviction)
      expect(engine.echoes_by_type(echo_type: :bias).size).to eq(1)
    end

    it 'returns empty array when no matching type' do
      engine.create_echo(content: 'a', echo_type: :belief)
      expect(engine.echoes_by_type(echo_type: :hypothesis)).to be_empty
    end
  end

  describe '#loudest_echoes' do
    it 'returns echoes sorted by amplitude descending' do
      engine.create_echo(content: 'quiet', amplitude: 0.3)
      loud = engine.create_echo(content: 'loud', amplitude: 0.9)
      expect(engine.loudest_echoes(limit: 1).first.id).to eq(loud.id)
    end

    it 'respects limit parameter' do
      3.times { |i| engine.create_echo(content: "echo #{i}") }
      expect(engine.loudest_echoes(limit: 2).size).to eq(2)
    end
  end

  describe '#most_sealed_chambers' do
    it 'returns chambers sorted by wall_thickness descending' do
      engine.create_chamber(label: 'thin', wall_thickness: 0.2)
      thick = engine.create_chamber(label: 'thick', wall_thickness: 0.9)
      expect(engine.most_sealed_chambers(limit: 1).first.id).to eq(thick.id)
    end

    it 'respects limit parameter' do
      3.times { |i| engine.create_chamber(label: "chamber #{i}") }
      expect(engine.most_sealed_chambers(limit: 2).size).to eq(2)
    end
  end

  describe '#disruption_history' do
    it 'returns empty initially' do
      expect(engine.disruption_history).to be_empty
    end

    it 'returns a copy, not the internal array' do
      chamber = engine.create_chamber(label: 'test', wall_thickness: 0.2)
      engine.disrupt_chamber(chamber_id: chamber.id, force: 0.9)
      history = engine.disruption_history
      expect(history).not_to equal(engine.disruption_history)
    end
  end

  describe '#add_echo_to_chamber' do
    it 'adds echo to chamber successfully' do
      echo    = engine.create_echo(content: 'test')
      chamber = engine.create_chamber(label: 'test chamber')
      result  = engine.add_echo_to_chamber(echo_id: echo.id, chamber_id: chamber.id)
      expect(result[:success]).to be true
    end

    it 'returns error for unknown echo' do
      chamber = engine.create_chamber(label: 'test')
      result  = engine.add_echo_to_chamber(echo_id: 'bad', chamber_id: chamber.id)
      expect(result[:error]).to eq('echo not found')
    end

    it 'returns error for unknown chamber' do
      echo   = engine.create_echo(content: 'test')
      result = engine.add_echo_to_chamber(echo_id: echo.id, chamber_id: 'bad')
      expect(result[:error]).to eq('chamber not found')
    end
  end

  describe '#active_echoes' do
    it 'returns non-silent echoes' do
      engine.create_echo(content: 'active', amplitude: 0.5)
      engine.create_echo(content: 'silent', amplitude: 0.01)
      expect(engine.active_echoes.size).to eq(1)
    end
  end

  describe '#resonating_echoes' do
    it 'returns echoes above disruption threshold' do
      engine.create_echo(content: 'resonating', amplitude: 0.8)
      engine.create_echo(content: 'quiet', amplitude: 0.3)
      expect(engine.resonating_echoes.size).to eq(1)
    end
  end

  describe '#echo_report' do
    it 'includes expected keys' do
      report = engine.echo_report
      expect(report).to include(
        :total_echoes, :active_echoes, :resonating_echoes,
        :total_chambers, :sealed_chambers, :porous_chambers,
        :disruption_count, :loudest
      )
    end

    it 'counts sealed chambers correctly' do
      engine.create_chamber(label: 'sealed', wall_thickness: 0.9)
      engine.create_chamber(label: 'open', wall_thickness: 0.2)
      expect(engine.echo_report[:sealed_chambers]).to eq(1)
    end

    it 'counts porous chambers correctly' do
      engine.create_chamber(label: 'porous', wall_thickness: 0.1)
      expect(engine.echo_report[:porous_chambers]).to eq(1)
    end

    it 'includes loudest echoes array' do
      engine.create_echo(content: 'loud', amplitude: 0.9)
      expect(engine.echo_report[:loudest]).not_to be_empty
    end
  end

  describe '#echo_by_id' do
    it 'returns the echo if found' do
      echo = engine.create_echo(content: 'find me')
      expect(engine.echo_by_id(echo.id)).to eq(echo)
    end

    it 'returns nil if not found' do
      expect(engine.echo_by_id('missing')).to be_nil
    end
  end

  describe '#chamber_by_id' do
    it 'returns the chamber if found' do
      chamber = engine.create_chamber(label: 'find me')
      expect(engine.chamber_by_id(chamber.id)).to eq(chamber)
    end

    it 'returns nil if not found' do
      expect(engine.chamber_by_id('missing')).to be_nil
    end
  end
end
