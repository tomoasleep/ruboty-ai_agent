# frozen_string_literal: true

module RequestFactory
  include RobotFactory

  def create_request(robot:, message:) #: Ruboty::AiAgent::Request
    ruboty_message = create_ruboty_message(robot:, **message)
    database = Ruboty::AiAgent::Database.new(robot.brain)

    Ruboty::AiAgent::Request.new(
      message: ruboty_message,
      chat_thread: database.chat_thread(ruboty_message.from)
    )
  end

  def create_ruboty_message(robot:, body:, from: 'from', to: 'to', **attributes) #: Ruboty::Message
    Ruboty::Message.new(attributes.merge(robot:, from:, to:, body:))
  end
end
