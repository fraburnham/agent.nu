use std/assert
use runner

use ../src/context

module api.nu {
  export def --wrapped "api chat" [...args] {
    runner stub STUB_API_CHAT --pipe-passthrough ...$args
  }
}

module tools/utils.nu {
  export def --wrapped "utils run" [...args] {
    runner stub STUB_UTILS_USE --pipe-passthrough ...$args
  }
}

module history.nu {
  export def "history start worker" [...args] {
    1
  }

  export def --wrapped "history update" [...args] {
    runner stub STUB_HISTORY_UPDATE --pipe-passthrough ...$args
  }
}

overlay use api.nu
overlay use tools/utils.nu
overlay use history.nu

use ../src/agent-loop.nu

const mock_persona = "high-level-leader"
const mock_config = {
  ollama_host: "http://mock.ollama.host"
  personas_path: "./personas"
  tools_path: "./src/tools"
}

def start-agent [] {
  job flush

  let agent_job_id = agent-loop run $mock_config $mock_persona (job id) (job id) (context initial $mock_config $mock_persona)
  # Wait for agent to become ready
  let initial_context = job recv --timeout 0.1sec

  [$agent_job_id, $initial_context]
}

def stop-agent [
  job_id: int
] {
  job kill $job_id
  job flush
}

def "test agent-loop can be killed with an exit message" [] {
  let agent_job_id = start-agent
  | first

  {
    type: user-input
    user_input: "/exit"
  }
  | job send $agent_job_id

  # Wait for agent to handle message and die
  job recv --timeout 0.1sec
  sleep 0.1sec

  assert (
    job list
    | where id == $agent_job_id
    | is-empty
  )
}

# ignore
def "test agent-loop does not leak a history worker" [] { # TODO
  let agent_job_id = start-agent
  | first

  {
    type: user-input
    user_input: "/exit"
  }
  | job send $agent_job_id

  # Wait for agent to handle message
  job recv --timeout 0.1sec

  assert (
    job list
    | where tag == history-worker
    | is-empty
  )
}

def "test agent-loop ignores unknown message types" [] {
  let start_result = start-agent
  let agent_job_id = $start_result
  | first
  let initial_context = $start_result
  | last

  {
    type: whoa
    whoa: "This is wild"
  }
  | job send $agent_job_id

  let response = job recv --timeout 0.1sec

  assert equal $initial_context $response

  stop-agent $agent_job_id
}

def "test agent-loop updates history" [] {
  with-env {
    STUB_HISTORY_UPDATE: { |...args|
      let context = $in

      assert equal (context initial $mock_config high-level-leader) $context

      {
        in: $in
      }
    }
  } {
    let start_result = start-agent
    let agent_job_id = $start_result
    | first
    let initial_context = $start_result
    | last

    {
      type: IGNORE-ME
    }
    | job send $agent_job_id

    job recv --timeout 0.1sec

    stop-agent $agent_job_id
  }
}

def "test agent-loop handles tool use" [] {
  let tool_calls = [
    {
      id: "mock-call-id"
      function: {
        index: 0
        name: "mock-function"
        arguments: {
          mock-parameter: "mock-parameter-value"
        }
      }
    }
  ]

  let response_with_tool_call = {
    role: "assistant"
    content: ""
    thinking: "mock-thinking"
    tool_calls: $tool_calls
  }

  with-env {
    STUB_API_CHAT: { |...args|
      let context = $in

      {
        in: (
          $response_with_tool_call
          | context append response $context
        )
      }
    }

    STUB_UTILS_USE: { |...args|
      let context = $in

      let actual_tool_calls = $context.messages
      | last
      | get tool_calls?

      assert equal $tool_calls $actual_tool_calls

      {
        in: $context
      }
    }
  } {
    let agent_job_id = start-agent
    | first

    {
      type: IGNORE-ME
    }
    | job send $agent_job_id

    job recv --timeout 0.1sec

    stop-agent $agent_job_id
  }
}

def "test agent-loop sends a chat message" [] {
  with-env {
    STUB_API_CHAT: { |...args|
      let context = $in

      assert equal (context initial $mock_config high-level-leader) $context
      
      {
        in: $in
      }
    }
  } {
    let agent_job_id = start-agent
    | first

    {
      type: IGNORE-ME
    }
    | job send $agent_job_id

    job recv --timeout 0.1sec

    stop-agent $agent_job_id
  }
}

export def main [] {
  runner run
}
