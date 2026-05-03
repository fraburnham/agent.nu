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

def "test that responses are appended to context correctly" [] {
  let context = {
    role: "assistant"
    content: "mock"
  }
  | context append response (context initial $mock_config $mock_persona)

  assert equal "mock" $context.messages.1.content
  assert equal "assistant" $context.messages.1.role
}

def "test that prompts are appended to context correctly" [] {
  let prompt = "This is only a test"

  let context = context initial $mock_config $mock_persona
  | context append prompt $prompt

  assert equal $prompt $context.messages.1.content
  assert equal "user" $context.messages.1.role

  let context = context initial $mock_config $mock_persona
  | context append prompt ""

  assert equal (context initial $mock_config $mock_persona) $context
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
