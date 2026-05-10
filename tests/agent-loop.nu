use std/assert
use runner

use ../src/context

module api.nu {
  export def --wrapped "api chat" [...args] {
    runner stub STUB_API_CHAT --pipe-passthrough ...$args
  }
}

module tools.nu {
  export def --wrapped "tools handle calls" [...args] {
    let input = $in

    if ($env.STUB_TOOLS_HANDLE_CALLS? | is-empty) {
      $env.STUB_TOOLS_HANDLE_CALLS = { |...args|
        []
      }
    }

    $input
    | runner stub STUB_TOOLS_HANDLE_CALLS --pipe-passthrough ...$args
  }
}

module context {
  export use ../src/context *

  export def --wrapped "history update" [...args] {
    runner stub STUB_HISTORY_UPDATE --pipe-passthrough ...$args
  }
}

overlay use api.nu
overlay use tools.nu
overlay use context

use ../src/agent-loop.nu

const mock_persona = "high-level-leader"
const mock_config = {
  ollama_host: "http://mock.ollama.host"
  personas_path: "./tests/mock/personas"
  tools_path: "./tests/mock/tools"
}

def start-agent [
  user_message: record
] {
  job flush

  let initial_context = context initial $mock_config $mock_persona
  | do {
    let context = $in

    if ($user_message | is-not-empty) {
      $user_message
      | context append message $context
    } else {
      $context
    }
  }

  let agent_job_id = agent-loop run {
    config: $mock_config
    persona: $mock_persona
    manager_job_id: (job id)
    initial_context: $initial_context
    history_path: ""
  }

  # Await first send from loop start
  job recv --timeout 0.1sec

  $agent_job_id
}

def stop-agent [
  job_id: int
] {
  job kill $job_id
  job flush
}

def "test agent-loop can be killed with an exit message" [] {
  let agent_job_id = start-agent {}

  {
    type: user-input
    user_input: {
      role: user
      content: "/exit"
    }
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

def "test agent-loop does not leak a history worker" [] {
  let agent_job_id = start-agent {}

  # Make sure two jobs started
  assert equal 2 (job list | length)
  
  {
    type: user-input
    user_input: {
      role: user
      content: "/exit"
    }
  }
  | job send $agent_job_id

  # Wait for agent to send exit message to controller
  job recv --timeout 0.1sec

  # Make sure all jobs got cleaned up
  assert (
    job list
    | is-empty
  )
}

def "test agent-loop updates history" [] {
  let user_message = {
    role: user
    content: mock
  }

  let assistant_message = {
    role: assistant
    content: mock
  }
  
  let possible_messages = context initial $mock_config high-level-leader
  | get messages
  | append $user_message
  | append $assistant_message
  
  with-env {
    STUB_API_CHAT: { |...args|
      {
        in: $assistant_message
      }
    }
    
    STUB_HISTORY_UPDATE: { |...args|
      let message = $in

      assert ($message in $possible_messages)

      {in: $message}
    }
  } {
    let agent_job_id = start-agent $user_message

    # agent-loop sends a message to the controller each time it advances
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
      {in: $response_with_tool_call}
    }

    STUB_TOOLS_HANDLE_CALLS: { |...args|
      let context = $in

      let actual_tool_calls = $context.messages
      | last
      | get tool_calls?

      assert equal $tool_calls $actual_tool_calls

      {
        in: []
      }
    }
  } {
    let agent_job_id = start-agent {
      role: user
      content: mock
    }

    job recv --timeout 0.1sec

    stop-agent $agent_job_id
  }
}

def "test agent-loop sends a chat message" [] {
  let user_message = {
      role: user
      content: "mock"
  }
  
  with-env {
    STUB_API_CHAT: { |...args|
      let context = $in
      let expected = $user_message
      | context append message (context initial $mock_config high-level-leader)

      assert equal $expected $context
      
      {
        in: {
          role: "assistant"
          content: "mock content"
          thinking: "mock thinking"
        }
      }
    }
  } {
    let agent_job_id = start-agent $user_message

    # Await the agent loop sending the api response to the controller
    job recv --timeout 0.1sec

    stop-agent $agent_job_id
  }
}

# TODO: test that "non-terminal" responses are advanced
# thinking but no content
# tool calls but no content
# others?

# TODO: these tests are pretty weak. Make them confirm that the stubs were called at all.

export def main [] {
  runner run
}

