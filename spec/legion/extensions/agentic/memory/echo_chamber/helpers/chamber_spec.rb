# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::EchoChamber::Helpers::Chamber do
  subject(:chamber) { described_class.new(label: 'political beliefs', domain: :politics) }

  let(:echo) do
    Legion::Extensions::Agentic::Memory::EchoChamber::Helpers::Echo.new(
      content: 'my side is always right',
      domain:  :politics
    )
  end

  let(:strong_echo) do
    Legion::Extensions::Agentic::Memory::EchoChamber::Helpers::Echo.new(
      content:   'opponents are always wrong',
      domain:    :politics,
      amplitude: 0.9
    )
  end

  describe '#initialize' do
    it 'assigns a UUID id' do
      expect(chamber.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'stores label' do
      expect(chamber.label).to eq('political beliefs')
    end

    it 'stores domain' do
      expect(chamber.domain).to eq(:politics)
    end

    it 'initializes state as :forming' do
      expect(chamber.state).to eq(:forming)
    end

    it 'defaults wall_thickness to 0.5' do
      expect(chamber.wall_thickness).to eq(0.5)
    end

    it 'initializes resonance_frequency to 0.0' do
      expect(chamber.resonance_frequency).to eq(0.0)
    end

    it 'initializes disruption_count to 0' do
      expect(chamber.disruption_count).to eq(0)
    end

    it 'records created_at' do
      expect(chamber.created_at).to be_a(Time)
    end

    it 'clamps wall_thickness above 1.0' do
      thick = described_class.new(label: 'x', wall_thickness: 2.0)
      expect(thick.wall_thickness).to eq(1.0)
    end

    it 'clamps wall_thickness below 0.0' do
      thin = described_class.new(label: 'x', wall_thickness: -1.0)
      expect(thin.wall_thickness).to eq(0.0)
    end
  end

  describe '#add_echo' do
    it 'returns true on success' do
      expect(chamber.add_echo(echo)).to be true
    end

    it 'increases echo_count' do
      chamber.add_echo(echo)
      expect(chamber.echo_count).to eq(1)
    end

    it 'updates resonance_frequency' do
      chamber.add_echo(strong_echo)
      expect(chamber.resonance_frequency).to be > 0.0
    end
  end

  describe '#remove_echo' do
    before { chamber.add_echo(echo) }

    it 'returns true when echo exists' do
      expect(chamber.remove_echo(echo.id)).to be true
    end

    it 'decreases echo_count' do
      chamber.remove_echo(echo.id)
      expect(chamber.echo_count).to eq(0)
    end

    it 'returns false when echo does not exist' do
      expect(chamber.remove_echo('nonexistent-id')).to be false
    end
  end

  describe '#amplify_all!' do
    before do
      chamber.add_echo(echo)
      chamber.add_echo(strong_echo)
    end

    it 'returns a hash with amplified count' do
      result = chamber.amplify_all!
      expect(result[:amplified]).to eq(2)
    end

    it 'returns updated resonance_frequency' do
      result = chamber.amplify_all!
      expect(result[:resonance_frequency]).to be_a(Float)
    end

    it 'increases amplitudes of echoes' do
      original = echo.amplitude
      chamber.amplify_all!
      expect(echo.amplitude).to be > original
    end
  end

  describe '#disrupt!' do
    context 'with insufficient force' do
      it 'returns success: false' do
        result = chamber.disrupt!(0.3)
        expect(result[:success]).to be false
      end

      it 'includes reason in result' do
        result = chamber.disrupt!(0.3)
        expect(result[:reason]).to eq('insufficient_force')
      end
    end

    context 'with sufficient force' do
      subject(:thick_chamber) { described_class.new(label: 'ideology', wall_thickness: 0.4) }

      before { thick_chamber.add_echo(strong_echo) }

      it 'returns success: true' do
        result = thick_chamber.disrupt!(0.9)
        expect(result[:success]).to be true
      end

      it 'includes breakthrough value' do
        result = thick_chamber.disrupt!(0.9)
        expect(result[:breakthrough]).to be > 0.0
      end

      it 'reduces wall_thickness' do
        original = thick_chamber.wall_thickness
        thick_chamber.disrupt!(0.9)
        expect(thick_chamber.wall_thickness).to be < original
      end

      it 'increments disruption_count' do
        thick_chamber.disrupt!(0.9)
        expect(thick_chamber.disruption_count).to eq(1)
      end

      it 'transitions state to :disrupted' do
        thick_chamber.disrupt!(0.9)
        expect(thick_chamber.state).to eq(:disrupted)
      end

      it 'dampens echoes in the chamber' do
        original = strong_echo.amplitude
        thick_chamber.disrupt!(0.9)
        expect(strong_echo.amplitude).to be < original
      end
    end
  end

  describe '#sealed?' do
    it 'is false at default wall_thickness (0.5)' do
      expect(chamber.sealed?).to be false
    end

    it 'is true when wall_thickness >= 0.8' do
      thick = described_class.new(label: 'x', wall_thickness: 0.85)
      expect(thick.sealed?).to be true
    end
  end

  describe '#porous?' do
    it 'is false at default wall_thickness (0.5)' do
      expect(chamber.porous?).to be false
    end

    it 'is true when wall_thickness <= 0.3' do
      thin = described_class.new(label: 'x', wall_thickness: 0.2)
      expect(thin.porous?).to be true
    end
  end

  describe '#resonance_level' do
    it 'returns :silent with no echoes' do
      expect(chamber.resonance_level).to eq(:silent)
    end

    it 'returns a symbol after adding resonating echoes' do
      resonating = Legion::Extensions::Agentic::Memory::EchoChamber::Helpers::Echo.new(
        content:   'strong belief',
        amplitude: 0.9
      )
      chamber.add_echo(resonating)
      expect(chamber.resonance_level).to be_a(Symbol)
    end
  end

  describe '#active_echoes' do
    it 'returns empty array initially' do
      expect(chamber.active_echoes).to be_empty
    end

    it 'returns echoes that are not silent' do
      chamber.add_echo(echo)
      expect(chamber.active_echoes.size).to eq(1)
    end
  end

  describe '#resonating_echoes' do
    it 'returns empty when no high-amplitude echoes' do
      chamber.add_echo(echo)
      expect(chamber.resonating_echoes).to be_empty
    end

    it 'returns echoes above disruption threshold' do
      chamber.add_echo(strong_echo)
      expect(chamber.resonating_echoes.size).to eq(1)
    end
  end

  describe '#to_h' do
    let(:hash) { chamber.to_h }

    it 'includes all expected keys' do
      expect(hash).to include(
        :id, :label, :domain, :state, :wall_thickness,
        :resonance_frequency, :resonance_level, :sealed, :porous,
        :echo_count, :active_echo_count, :disruption_count, :created_at
      )
    end

    it 'reflects current echo_count' do
      chamber.add_echo(echo)
      expect(chamber.to_h[:echo_count]).to eq(1)
    end
  end
end
