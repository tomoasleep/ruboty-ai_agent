# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ruboty::AiAgent::Actions::ListAiCommands do
  subject(:action) { described_class.new(message) }

  let(:robot) { Ruboty::Robot.new }
  let(:from) { 'test_user' }
  let(:to) { 'ruboty' }
  let(:body) { 'list ai commands' }

  let(:message) do
    msg = Ruboty::Message.new(
      body: body,
      from: from,
      to: to,
      robot: robot
    )
    allow(msg).to have_received(:reply)
    msg
  end

  describe '#call' do
    it 'replies with /clear command information' do
      expect(message).to have_received(:reply) do |reply_content|
        expect(reply_content).to include('/\\/clear/')
        expect(reply_content).to include('Clear the chat history.')
      end

      action.call
    end
  end
end
