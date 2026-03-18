# frozen_string_literal: true

RSpec.describe Legion::Extensions::Agentic::Memory::EchoChamber::Helpers::Echo do
  subject(:echo) { described_class.new(content: 'everything I believe is true') }

  describe '#initialize' do
    it 'assigns a UUID id' do
      expect(echo.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'stores content' do
      expect(echo.content).to eq('everything I believe is true')
    end

    it 'defaults echo_type to :belief' do
      expect(echo.echo_type).to eq(:belief)
    end

    it 'defaults domain to :general' do
      expect(echo.domain).to eq(:general)
    end

    it 'defaults amplitude to 0.5' do
      expect(echo.amplitude).to eq(0.5)
    end

    it 'preserves original_amplitude' do
      expect(echo.original_amplitude).to eq(0.5)
    end

    it 'initializes frequency to 1' do
      expect(echo.frequency).to eq(1)
    end

    it 'records created_at' do
      expect(echo.created_at).to be_a(Time)
    end

    it 'clamps amplitude above 1.0' do
      high = described_class.new(content: 'x', amplitude: 5.0)
      expect(high.amplitude).to eq(1.0)
    end

    it 'clamps amplitude below 0.0' do
      low = described_class.new(content: 'x', amplitude: -1.0)
      expect(low.amplitude).to eq(0.0)
    end

    it 'validates echo_type, falls back to :belief' do
      bad = described_class.new(content: 'x', echo_type: :nonsense)
      expect(bad.echo_type).to eq(:belief)
    end

    it 'accepts all valid echo types' do
      %i[belief assumption bias hypothesis conviction].each do |type|
        e = described_class.new(content: 'x', echo_type: type)
        expect(e.echo_type).to eq(type)
      end
    end

    it 'stores source_agent' do
      e = described_class.new(content: 'x', source_agent: 'agent-123')
      expect(e.source_agent).to eq('agent-123')
    end

    it 'accepts custom domain' do
      e = described_class.new(content: 'x', domain: :politics)
      expect(e.domain).to eq(:politics)
    end
  end

  describe '#amplify!' do
    it 'increases amplitude' do
      original = echo.amplitude
      echo.amplify!
      expect(echo.amplitude).to be > original
    end

    it 'increments frequency' do
      echo.amplify!
      expect(echo.frequency).to eq(2)
    end

    it 'clamps amplitude at 1.0' do
      high = described_class.new(content: 'x', amplitude: 0.95)
      5.times { high.amplify! }
      expect(high.amplitude).to eq(1.0)
    end

    it 'accepts custom rate' do
      original = echo.amplitude
      echo.amplify!(0.2)
      expect(echo.amplitude).to be_within(0.001).of(original + 0.2)
    end

    it 'returns self for chaining' do
      expect(echo.amplify!).to eq(echo)
    end
  end

  describe '#dampen!' do
    it 'decreases amplitude' do
      strong = described_class.new(content: 'x', amplitude: 0.8)
      original = strong.amplitude
      strong.dampen!
      expect(strong.amplitude).to be < original
    end

    it 'clamps amplitude at 0.0' do
      30.times { echo.dampen! }
      expect(echo.amplitude).to eq(0.0)
    end

    it 'accepts custom rate' do
      original = echo.amplitude
      echo.dampen!(0.1)
      expect(echo.amplitude).to be_within(0.001).of(original - 0.1)
    end

    it 'returns self for chaining' do
      expect(echo.dampen!).to eq(echo)
    end
  end

  describe '#resonate?' do
    it 'is false at default amplitude (0.5)' do
      expect(echo.resonate?).to be false
    end

    it 'is true when amplitude exceeds disruption threshold' do
      strong = described_class.new(content: 'x', amplitude: 0.8)
      expect(strong.resonate?).to be true
    end
  end

  describe '#fading?' do
    it 'is false at default amplitude (0.5)' do
      expect(echo.fading?).to be false
    end

    it 'is true when amplitude is at or below porous threshold' do
      weak = described_class.new(content: 'x', amplitude: 0.2)
      expect(weak.fading?).to be true
    end
  end

  describe '#silent?' do
    it 'is false at default amplitude' do
      expect(echo.silent?).to be false
    end

    it 'is true when amplitude is at silent threshold' do
      faint = described_class.new(content: 'x', amplitude: 0.04)
      expect(faint.silent?).to be true
    end
  end

  describe '#frequency_label' do
    it 'returns a symbol' do
      expect(echo.frequency_label).to be_a(Symbol)
    end

    it 'returns :silent for frequency 1 (score 0.05)' do
      expect(echo.frequency_label).to eq(:silent)
    end

    it 'returns higher label after many amplifications' do
      20.times { echo.amplify! }
      expect(echo.frequency_label).not_to eq(:silent)
    end
  end

  describe '#amplitude_label' do
    it 'returns a symbol' do
      expect(echo.amplitude_label).to be_a(Symbol)
    end

    it 'returns :moderate for default amplitude 0.5' do
      expect(echo.amplitude_label).to eq(:moderate)
    end

    it 'returns :deafening for high amplitude' do
      loud = described_class.new(content: 'x', amplitude: 0.9)
      expect(loud.amplitude_label).to eq(:deafening)
    end

    it 'returns :muted for low amplitude' do
      quiet = described_class.new(content: 'x', amplitude: 0.1)
      expect(quiet.amplitude_label).to eq(:muted)
    end
  end

  describe '#to_h' do
    let(:hash) { echo.to_h }

    it 'includes :id' do
      expect(hash).to have_key(:id)
    end

    it 'includes :content' do
      expect(hash[:content]).to eq('everything I believe is true')
    end

    it 'includes :echo_type' do
      expect(hash[:echo_type]).to eq(:belief)
    end

    it 'includes :domain' do
      expect(hash[:domain]).to eq(:general)
    end

    it 'includes :amplitude' do
      expect(hash[:amplitude]).to eq(0.5)
    end

    it 'includes :original_amplitude' do
      expect(hash[:original_amplitude]).to eq(0.5)
    end

    it 'includes :frequency' do
      expect(hash[:frequency]).to eq(1)
    end

    it 'includes :frequency_label' do
      expect(hash).to have_key(:frequency_label)
    end

    it 'includes :amplitude_label' do
      expect(hash).to have_key(:amplitude_label)
    end

    it 'includes :resonate boolean' do
      expect(hash[:resonate]).to be(false).or be(true)
    end

    it 'includes :fading boolean' do
      expect(hash[:fading]).to be(false).or be(true)
    end

    it 'includes :silent boolean' do
      expect(hash[:silent]).to be(false).or be(true)
    end

    it 'includes :source_agent' do
      expect(hash).to have_key(:source_agent)
    end

    it 'includes :created_at' do
      expect(hash[:created_at]).to be_a(Time)
    end
  end
end
