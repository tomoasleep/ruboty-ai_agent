# frozen_string_literal: true

require 'spec_helper'

describe Ruboty::Handlers::AiAgent do
  let(:robot) do
    Ruboty::Robot.new
  end

  it 'replies to ping' do
    expect(robot).to receive(:say).with(
      body: 'pong',
      from: 'dummy',
      to: 'ruboty',
      original: {
        body: 'ruboty ping',
        from: 'dummy',
        to: 'ruboty'
      }
    )
    robot.receive(body: 'ruboty ping', from: 'dummy', to: 'ruboty')
  end
end
