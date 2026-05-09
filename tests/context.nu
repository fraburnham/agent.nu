use std/assert
use runner

use ../src/personas.nu
use ../src/tools.nu

use ../src/context

const mock_persona = "high-level-leader"
const mock_config = {
  ollama_host: "http://mock.host"
  personas_path: "./tests/mock/personas"
  tools_path: "./tests/mock/tools"
}

def "test that messages are appended to context correctly" [] {
  let context = {
    role: "assistant"
    content: "mock"
  }
  | context append message (context initial $mock_config $mock_persona)

  assert equal "mock" $context.messages.1.content
  assert equal "assistant" $context.messages.1.role
}

def "test that initial context is set up with a system message and appropriate tools" [] {
  let context = context initial $mock_config $mock_persona

  assert equal "system" $context.messages.0.role
  assert equal (personas system prompt $mock_config $mock_persona) $context.messages.0.content
  assert equal (tools available to persona $mock_config $mock_persona) $context.tools
}

export def main [] {
  runner run
}

# TODO tests for history update
