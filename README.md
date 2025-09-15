# Ruboty::AiAgent

A Ruboty handler that uses LLMs (e.g., OpenAI) and MCP (Model Context Protocol) tools to generate AI-assisted replies. When an incoming message does not match any other handler, this plugin responds via an LLM and can call MCP tools when available.

## Installation

Add to your Gemfile:

```ruby
gem 'ruboty'
gem 'ruboty-ai_agent'
```

Then install:

```
bundle install
```

## Setup

### OpenAI

Configure environment variables (e.g., via `.env`):

- `OPENAI_API_KEY`: Your LLM provider API key (required)
- `OPENAI_MODEL`: Model name (optional)

 

## Usage

- Any message that does not match other handlers is sent to the AI and replied to.
- Conversations are tracked per thread, and tools exposed via MCP servers can be invoked through function calls when the model requests them.

## Commands

Conversation management:
- `/clear` — Clear the current thread’s conversation history
- `/compact` — Summarize and compact the conversation history

System prompt (work in progress):
- `set system prompt "<PROMPT>"` — Set the system prompt (WIP)
- `show system prompt` — Show the current system prompt (WIP)

AI memory (lightweight profile):
- `add ai memory "<TEXT>"` — Add a memory entry
- `remove ai memory <INDEX>` — Remove a memory by index
- `list ai memories` — List all memory entries

AI custom commands (work in progress):
- `add ai command /<NAME> "<PROMPT>"` — Add a custom AI command (WIP)
- `remove ai command /<NAME>` — Remove a custom AI command (WIP)
- `list ai commands` — List available built-in commands

MCP (Model Context Protocol):
- `add mcp <NAME> <OPTIONS> <URL>` — Add an MCP server
  - Example (HTTP transport with auth header):
    - `add mcp search --transport http --header 'Authorization: Bearer xxx' https://example.com/mcp`
    - `add mcp search --transport http --bearer-token xxx https://example.com/mcp`
  - Options:
    - `--transport http|sse` (currently only `http` implemented; `sse` is not yet implemented)
    - `--header 'Key: Value'` (repeatable)
    - `--bearer-token <TOKEN>` (shorthand for `--header 'Authorization: Bearer <TOKEN>'`)
- `remove mcp <NAME>` — Remove an MCP server
- `list mcp` / `list mcps` — List configured MCP servers

## How It Works

- Unmatched messages are handled by `Ruboty::Handlers::AiAgent#chat` and sent to the configured LLM.
- If MCP servers are configured, their tool definitions are exposed to the model; when the model requests a function call, the corresponding MCP tool is invoked and its response is fed back into the conversation.
- During tool calls, the bot streams short status updates and returns a brief summary of the tool’s response.
- Conversation data is stored in Ruboty’s brain under the `:ai_agent` namespace.


## Development

Install dependencies:

```
bin/setup
```

Local run with dotenv (for development):

```
bundle exec ruboty --dotenv

# or using the included launcher
bin/ruboty --dotenv
```

Run tests:

```
rake spec
```

Interactive console:

```
bin/console
```

Install locally:

```
bundle exec rake install
```

Release:
Update `version.rb` and run `bundle exec rake release` to tag, push, and publish to RubyGems.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tomoasleep/ruboty-ai_agent.

## Code of Conduct

Everyone interacting in the Ruboty::AiAgent project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/tomoasleep/ruboty-ai_agent/blob/main/CODE_OF_CONDUCT.md).
