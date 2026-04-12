use std/assert
use runner

module mock/post {
  export def --wrapped "http post" [...args] {
    do $env.MOCK_HANDLER ...$args
  }
}
overlay use mock/post

use ../src/api.nu

def "test that chat call appends the response onto the context" [] {
  with-env {
    MOCK_HANDLER: { |...args|
      {
        message: {
          role: "assistant"
          content: "mock"
        }
      }
    }
  } {
    {messages: []}
    | api chat --model "mock-model" --host "mock-host"
    | do {
      assert equal "mock" $in.messages.0.content
      assert equal "assistant" $in.messages.0.role
    }
  }
}

def "test that chat call appends the response onto the context when tool calls are present" [] {
  with-env {
    MOCK_HANDLER: { |...args|
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
    | api chat --model "mock-model" --host "mock-host"
    | do {
      assert equal "" $in.messages.0.content
      assert equal "assistant" $in.messages.0.role
      assert equal ["mock"] $in.messages.0.tool_calls
    }
  }
}

export def main [] {
  runner run
}
