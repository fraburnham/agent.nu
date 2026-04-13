use std/assert
use runner

use ../src/personas.nu [personas]
use ../src/tools/utils.nu
use ../src/tools/definitions.nu [tool_schemas]

use ../src/context

def "test that responses are appended to context correctly" [] {
  let context = {
    role: "assistant"
    content: "mock"
  }
  | context append response (context initial high-level-leader)

  assert equal "mock" $context.messages.1.content
  assert equal "assistant" $context.messages.1.role
}

def "test that prompts are appended to context correctly" [] {
  let prompt = "This is only a test"

  let context = context initial high-level-leader
  | context append prompt $prompt

  assert equal $prompt $context.messages.1.content
  assert equal "user" $context.messages.1.role

  let context = context initial high-level-leader
  | context append prompt ""

  assert equal (context initial high-level-leader) $context
}

def "test that initial context is set up with a system message and appropriate tools" [] {
  let context = context initial high-level-leader

  assert equal "system" $context.messages.0.role
  assert equal $personas.high-level-leader $context.messages.0.content
  assert equal (utils available to agent $tool_schemas high-level-leader) $context.tools
}

export def main [] {
  runner run
}
