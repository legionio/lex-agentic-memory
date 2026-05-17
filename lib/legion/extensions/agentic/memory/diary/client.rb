# frozen_string_literal: true

require 'legion/extensions/agentic/memory/diary/helpers/constants'
require 'legion/extensions/agentic/memory/diary/helpers/diary_store'
require 'legion/extensions/agentic/memory/diary/runners/diary'

module Legion
  module Extensions
    module Agentic
      module Memory
        module Diary
          class Client
            include Runners::Diary

            def initialize(agent_id: nil, store: nil)
              @diary_store = store || Helpers::DiaryStore.new(agent_id: agent_id)
            end

            private

            attr_reader :diary_store
          end
        end
      end
    end
  end
end
