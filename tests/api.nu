use std/assert
use runner

export def --wrapped "http post" [...args] {
  runner stub STUB_HTTP_POST ...$args
}

use ../src/api.nu

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
    | api chat --model "mock-model" --host "mock-host"
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
    | api chat --model "mock-model" --host "mock-host"
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
    | api chat --model "mock-model" --host "mock-host"
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
    | api chat --model "mock-model" --host "mock-host"
    | do {
      assert equal "mock-model" $in.messages.0.content.model
      assert equal false $in.messages.0.content.stream
    }
  }
}


export def main [] {
  runner run
}
