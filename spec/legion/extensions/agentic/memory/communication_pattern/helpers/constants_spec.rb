# frozen_string_literal: true

require 'spec_helper'
require 'legion/extensions/agentic/memory/communication_pattern/helpers/constants'

RSpec.describe Legion::Extensions::Agentic::Memory::CommunicationPattern::Helpers::Constants do
  describe 'HOURS_IN_DAY' do
    it 'is 24' do
      expect(described_class::HOURS_IN_DAY).to eq(24)
    end
  end

  describe 'DAYS_IN_WEEK' do
    it 'is 7' do
      expect(described_class::DAYS_IN_WEEK).to eq(7)
    end
  end

  describe 'MESSAGE_LENGTH_BUCKETS' do
    it 'defines 3 buckets' do
      expect(described_class::MESSAGE_LENGTH_BUCKETS).to eq(%i[short medium long])
    end
  end

  describe 'SLIDING_WINDOW_SIZE' do
    it 'is 100' do
      expect(described_class::SLIDING_WINDOW_SIZE).to eq(100)
    end
  end

  describe 'MIN_TRACES_FOR_PATTERN' do
    it 'is 10' do
      expect(described_class::MIN_TRACES_FOR_PATTERN).to eq(10)
    end
  end
end
