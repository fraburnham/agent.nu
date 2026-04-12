use std/assert
use runner

hide "http post"

def --wrapped "http post" [
  ...args
] {
  {
    message: {
      role: "assistant"
      content: "mock"
    }
  }
}

use ../src/api.nu

def "test that chat call appends the response onto the context" [] {
  {messages: []}
  | api chat --model "mock-model" --host "mock-host"
  | do {
    assert equal "mock" $in.messages.0.content
    assert equal "assistant" $in.messages.0.role
  }
}

export def main [] {
  runner run
}
