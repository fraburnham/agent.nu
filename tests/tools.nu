use std/assert
use runner

module tools/delegate-work.nu {
  # idk why `export def main` doesn't work here...
  export def delegate-work [
    reply_to_job_id: int
    params: record
  ] {
    runner stub STUB_DELEGATE_WORK --args-passthrough $params
  }
}

overlay use tools/delegate-work.nu

use ../src/tools.nu

def "test the tool runner executes tools" [] {
  let tool_handler_job_id = tools run handler

  {
    context: {
      messages: [{
        tool_calls: [{
          id: "mock-id"
          function: {
            index: 0
            name: "delegate-work"
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
    content: [[mock, is]; ["stuff", "cool"]] # Not fully sure why this is in table syntax...
  }

  assert equal $expected ($response.context.messages | last)
}

def "test the tool runner ignores unknown tools" [] {
  let tool_handler_job_id = tools run handler

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
    content: "No matching tool found."
  }

  assert equal $expected ($response.context.messages | last)
}

export def main [] {
  runner run
}
