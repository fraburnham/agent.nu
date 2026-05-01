use std/assert
use runner

use ../src/tools.nu

const mock_config = {
  ollama_host: "http://mock.ollama.host"
  personas_path: "./tests/mock/personas"
  tools_path: "./tests/mock/tools"
}

def "test the tool runner executes tools" [] {
  let tool_handler_job_id = tools run handler $mock_config
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

  {
    context: {
      messages: [{
        tool_calls: [$tool_call]
      }]
    }
    reply_to_job_id: (job id)
  }
  | job send $tool_handler_job_id

  let response = job recv --timeout 0.1sec

  let expected = {
    config: $mock_config
    tool_call: $tool_call
  }

  assert equal $expected ($response.context.messages | last | get content | from json)
}

def "test the tool runner ignores unknown tools" [] {
  let tool_handler_job_id = tools run handler $mock_config

  {
    context: {
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
    reply_to_job_id: (job id)
  }
  | job send $tool_handler_job_id

  let response = job recv --timeout 0.1sec

  let expected = {
    id: "mock-id"
    role: "tool"
    content: "No matching tool found. Retrying the call will not help."
  }

  assert equal $expected ($response.context.messages | last)
}

export def main [] {
  runner run
}
