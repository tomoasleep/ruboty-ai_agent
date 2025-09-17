# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ruboty::AiAgent::ToolDefinitions::BotHelp do
  include RobotFactory
  include DatabaseFactory

  let(:robot) { create_robot }
  let(:database) { Ruboty::AiAgent::Database.new(robot.brain) }
  let(:chat_thread) { database.chat_thread('test_user') }
  let(:message) do
    Ruboty::Message.new(body: 'test message',
                        from: 'test_user',
                        to: 'ruboty',
                        robot: robot)
  end
  let(:request) { Ruboty::AiAgent::Request.new(message: message, chat_thread: chat_thread) }
  let(:tool_instance) { described_class.new(request: request) }

  describe '#call' do
    subject(:call_result) { tool_instance.call(arguments) }

    # Use actual Ruboty actions that are automatically registered
    let(:actual_actions) { Ruboty.actions }

    context 'without filter' do
      let(:arguments) { {} }

      it 'returns all available commands help' do
        # Should contain the actual Ruboty commands
        expect(call_result).to include('Show this help message')
        expect(call_result).to include('Return PONG to PING')
        expect(call_result).to include('Answer who you are')
        expect(call_result).to include('AI responds to your message')
      end

      it 'formats commands with robot name prefix for non-all commands' do
        # Most commands should have robot name prefix (since they're not 'all' commands)
        expect(call_result).to include("#{robot.name} /help")
        expect(call_result).to include("#{robot.name} /ping")
        expect(call_result).to include("#{robot.name} /who am i")
      end

      it 'does not include hidden commands' do
        # Verify that hidden commands (if any) are not included
        hidden_actions = actual_actions.select(&:hidden?)
        hidden_actions.each do |action|
          expect(call_result).not_to include(action.description)
        end
      end

      it 'includes the correct number of non-hidden actions' do
        non_hidden_count = actual_actions.reject(&:hidden?).size
        result_lines = call_result.split("\n")
        expect(result_lines.size).to eq(non_hidden_count)
      end
    end

    context 'with filter that matches commands' do
      let(:arguments) { { 'filter' => 'help' } }

      it 'returns only matching commands' do
        expect(call_result).to include('Show this help message')
        expect(call_result).not_to include('Return PONG to PING')
        expect(call_result).not_to include('Answer who you are')
      end
    end

    context 'with filter that matches multiple commands' do
      let(:arguments) { { 'filter' => 'ai' } }

      it 'returns all matching commands' do
        # Should match AI-related commands based on actual registered actions
        # Check the actual descriptions that contain 'ai'
        expect(call_result).to include('Add a new AI memory')
        expect(call_result).to include('Add a new AI command')
        expect(call_result).to include('List AI commands')
        expect(call_result).not_to include('Return PONG to PING')
      end
    end

    context 'with filter that matches no commands' do
      let(:arguments) { { 'filter' => 'nonexistent_command_xyz' } }

      it 'returns no match message' do
        expect(call_result).to eq("No description matched to 'nonexistent_command_xyz'")
      end
    end

    context 'with filter matching MCP commands' do
      let(:arguments) { { 'filter' => 'mcp' } }

      it 'returns MCP-related commands' do
        expect(call_result).to include('Add a new MCP server')
        expect(call_result).to include('Remove the specified MCP server')
        expect(call_result).to include('List configured MCP servers')
        expect(call_result).not_to include('Return PONG to PING')
      end
    end
  end

  describe '#to_tool' do
    subject(:tool) { tool_instance.to_tool }

    it 'creates a Tool instance with correct attributes' do
      expect(tool.name).to eq('bot_help')
      expect(tool.title).to eq('Show help information about this bot (you)')
      expect(tool.description).to include('Get help information about available patterns of this bot (you).')
    end

    it 'has proper input schema' do
      expect(tool.input_schema[:type]).to eq('object')
      expect(tool.input_schema[:properties]).to have_key(:filter)
    end

    it 'is not silent' do
      expect(tool).not_to be_silent
    end
  end

  describe 'integration with real Ruboty help behavior' do
    subject(:call_result) { tool_instance.call({}) }

    it 'produces the same output format as original Ruboty help action' do
      # Capture the original help output by using the same logic as Ruboty::Actions::Help
      original_descriptions = Ruboty.actions.reject(&:hidden?).sort_by(&:description).map do |action|
        prefix = ''
        prefix += "#{robot.name} " unless action.all?
        "#{prefix}#{action.pattern.inspect} - #{action.description}"
      end
      original_output = original_descriptions.join("\n")

      expect(call_result).to eq(original_output)
    end
  end
end
