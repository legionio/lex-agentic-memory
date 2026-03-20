# frozen_string_literal: true

require 'spec_helper'
require 'legion/extensions/agentic/memory/trace/helpers/snapshot'
require 'tmpdir'
require 'msgpack'

RSpec.describe Legion::Extensions::Agentic::Memory::Trace::Helpers::Snapshot do
  let(:tmpdir) { Dir.mktmpdir('legion-snapshot-test') }
  let(:agent_id) { 'test-agent' }

  before do
    allow(described_class).to receive(:snapshot_dir) do |aid|
      File.join(tmpdir, aid.to_s)
    end
    Legion::Extensions::Agentic::Memory::Trace.reset_store!
  end

  after do
    FileUtils.rm_rf(tmpdir)
  end

  describe '.save_snapshot' do
    it 'creates a snapshot file' do
      result = described_class.save_snapshot(agent_id: agent_id)
      expect(result[:success]).to be true
      expect(result[:path]).to end_with('.snapshot')
      expect(File.exist?(result[:path])).to be true
    end

    it 'creates a non-empty file' do
      result = described_class.save_snapshot(agent_id: agent_id)
      expect(File.size(result[:path])).to be > 64
    end
  end

  describe '.restore_snapshot' do
    it 'restores from latest snapshot' do
      described_class.save_snapshot(agent_id: agent_id)
      result = described_class.restore_snapshot(agent_id: agent_id)
      expect(result[:success]).to be true
      expect(result[:agent_id]).to eq(agent_id)
    end

    it 'returns no_snapshot when none exists' do
      result = described_class.restore_snapshot(agent_id: 'nonexistent')
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:no_snapshot)
    end

    it 'detects tampered snapshot' do
      save_result = described_class.save_snapshot(agent_id: agent_id)
      data = File.binread(save_result[:path])
      data[0] = (data[0].ord ^ 0xFF).chr
      File.binwrite(save_result[:path], data)

      result = described_class.restore_snapshot(agent_id: agent_id)
      expect(result[:success]).to be false
    end
  end

  describe '.list_snapshots' do
    it 'lists saved snapshots' do
      described_class.save_snapshot(agent_id: agent_id)
      described_class.save_snapshot(agent_id: agent_id)
      result = described_class.list_snapshots(agent_id: agent_id)
      expect(result[:success]).to be true
      expect(result[:snapshots].size).to eq(2)
    end

    it 'returns empty list when no snapshots exist' do
      result = described_class.list_snapshots(agent_id: 'no-such-agent')
      expect(result[:snapshots]).to be_empty
    end
  end

  describe '.prune_snapshots' do
    it 'removes excess snapshots keeping newest' do
      15.times { described_class.save_snapshot(agent_id: agent_id) }
      result = described_class.prune_snapshots(agent_id: agent_id, max_count: 5)
      expect(result[:pruned]).to eq(5)

      list = described_class.list_snapshots(agent_id: agent_id)
      expect(list[:snapshots].size).to eq(5)
    end
  end
end
