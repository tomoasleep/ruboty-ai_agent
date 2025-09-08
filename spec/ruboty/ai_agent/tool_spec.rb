# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ruboty::AiAgent::Tool do
  describe '#call' do
    subject(:call_tool) { tool.call(params) }

    context 'with implementation block' do
      let(:tool) do
        described_class.new(
          name: 'string_manipulator',
          title: 'String Manipulator',
          description: 'Manipulates strings',
          input_schema: {
            'type' => 'object',
            'properties' => {
              'text' => { 'type' => 'string' },
              'operation' => { 'type' => 'string' }
            }
          }
        ) do |params|
          case params[:operation]
          when 'upcase'
            params[:text].upcase
          when 'downcase'
            params[:text].downcase
          when 'reverse'
            params[:text].reverse
          else
            params[:text]
          end
        end
      end

      context 'with upcase operation' do
        let(:params) { { text: 'Hello', operation: 'upcase' } }

        it { is_expected.to eq('HELLO') }
      end

      context 'with downcase operation' do
        let(:params) { { text: 'WORLD', operation: 'downcase' } }

        it { is_expected.to eq('world') }
      end

      context 'with reverse operation' do
        let(:params) { { text: 'Ruby', operation: 'reverse' } }

        it { is_expected.to eq('ybuR') }
      end

      context 'with unknown operation' do
        let(:params) { { text: 'Test', operation: 'unknown' } }

        it { is_expected.to eq('Test') }
      end
    end

    context 'without implementation block' do
      let(:tool) do
        described_class.new(
          name: 'no_op',
          title: 'No Operation',
          description: 'Does nothing',
          input_schema: nil
        )
      end

      context 'with empty parameters' do
        let(:params) { {} }

        it { is_expected.to be_nil }
      end

      context 'with some parameters' do
        let(:params) { { some: 'params' } }

        it { is_expected.to be_nil }
      end
    end

    context 'with error in block' do
      let(:tool) do
        described_class.new(
          name: 'error_tool',
          title: 'Error Tool',
          description: 'Tool that raises error',
          input_schema: nil
        ) do |_params|
          raise StandardError, 'Something went wrong'
        end
      end
      let(:params) { {} }

      it 'propagates the error' do
        expect { call_tool }.to raise_error(StandardError, 'Something went wrong')
      end
    end

    context 'with complex input schema' do
      let(:tool) do
        described_class.new(
          name: 'weather',
          title: 'Weather Tool',
          description: 'Gets weather information',
          input_schema: {
            'type' => 'object',
            'properties' => {
              'location' => {
                'type' => 'string',
                'description' => 'City name'
              },
              'units' => {
                'type' => 'string',
                'enum' => %w[celsius fahrenheit],
                'default' => 'celsius'
              },
              'include_forecast' => {
                'type' => 'boolean',
                'default' => false
              }
            },
            'required' => ['location']
          }
        ) do |params|
          location = params[:location]
          units = params[:units] || 'celsius'
          include_forecast = params[:include_forecast] || false

          temp = units == 'celsius' ? '25°C' : '77°F'
          result = "Weather in #{location}: Sunny, #{temp}"
          result += ' | Tomorrow: Cloudy' if include_forecast
          result
        end
      end

      context 'with minimal parameters' do
        let(:params) { { location: 'Tokyo' } }

        it { is_expected.to eq('Weather in Tokyo: Sunny, 25°C') }
      end

      context 'with fahrenheit units' do
        let(:params) { { location: 'New York', units: 'fahrenheit' } }

        it { is_expected.to eq('Weather in New York: Sunny, 77°F') }
      end

      context 'with forecast enabled' do
        let(:params) { { location: 'London', include_forecast: true } }

        it { is_expected.to eq('Weather in London: Sunny, 25°C | Tomorrow: Cloudy') }
      end
    end
  end
end
