use std/assert
use runner

use ../src/tools.nu

const mock_config = {
  ollama_host: "http://mock.ollama.host"
  personas_path: "./tests/mock/personas"
  tools_path: "./tests/mock/tools"
}

def "test the tool runner executes tools passing config and tool_call details" [] {
  let tool_call = {
    id: "mock-id"
    function: {
      index: 0
      name: "mock"
      arguments: {
        mock: "oh-mock"
      }
    }
  }

  let response = {
    messages: [{
      tool_calls: [$tool_call]
    }]
  }
  | tools handle calls $mock_config

  let expected = [
    {
      id: "mock-id"
      role: "tool"
      content: $"(
        {
          config: $mock_config
          tool_call: $tool_call
        }
        | to json
      )\n"
    }
  ]

  assert equal $expected $response
}

def "test the tool runner ignores unknown tools" [] {
  let response = {
    messages: [{
      tool_calls: [{
        id: "mock-id"
        function: {
          index: 0
          name: "flargen"
          arguments: {
            mock: "stuff"
            is: "cool"
          }
        }
      }]
    }]
  }
  | tools handle calls $mock_config

  let expected = [{
    id: "mock-id"
    role: "tool"
    content: "No matching tool found. Retrying the call will not help."
  }]

  assert equal $expected $response
}

export def main [] {
  runner run
}
