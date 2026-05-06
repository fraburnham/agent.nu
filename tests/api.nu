use std/assert
use runner

export def --wrapped "http post" [...args] {
  runner stub STUB_HTTP_POST ...$args
}

use ../src/api.nu

const mock_persona = "high-level-leader"
const mock_config = {
  ollama_host: "http://mock.host"
  personas_path: "./tests/mock/personas"
  tools_path: "./tests/mock/tools"
}

def "test that chat appends the response onto the context" [] {
  with-env {
    STUB_HTTP_POST: { |...args|
      {
        message: {
          role: "assistant"
          content: "mock"
        }
      }
    }
  } {
    {messages: []}
    | api chat $mock_config $mock_persona
    | do {
      assert equal "mock" $in.messages.0.content
      assert equal "assistant" $in.messages.0.role
    }
  }
}

def "test that chat does not return a context with stream or model" [] {
  with-env {
    STUB_HTTP_POST: { |...args|
      {
        message: {
          role: "assistant"
          content: "mock"
        }
      }
    }
  } {
    {messages: []}
    | api chat $mock_config $mock_persona
    | do {
      assert ($in.stream? | is-empty)
      assert ($in.model? | is-empty)
    }
  }
}

def "test that chat appends the response onto the context when tool calls are present" [] {
  with-env {
    STUB_HTTP_POST: { |...args|
      {
        message: {
          role: "assistant"
          content: ""
          tool_calls: [
            "mock"
          ]
        }
      }
    }
  } {
    {messages: []}
    | api chat $mock_config $mock_persona
    | do {
      assert equal "" $in.messages.0.content
      assert equal "assistant" $in.messages.0.role
      assert equal ["mock"] $in.messages.0.tool_calls
    }
  }
}

def "test that chat sets model and stream params" [] {
  with-env {
    STUB_HTTP_POST: { |...args|
      {
        message: {
          role: assistant
          content: ($in | from json)
        }
      }
    }
  } {
    {messages: []}
    | api chat $mock_config $mock_persona
    | do {
      # Model from default high-level-leader persona config
      assert equal "gemma4:26b-a4b-it-q4_K_M" $in.messages.0.content.model
      assert equal false $in.messages.0.content.stream
    }
  }
}


export def main [] {
  runner run
}
