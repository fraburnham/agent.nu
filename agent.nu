#!/usr/bin/env nu

use tui.nu

def context-manager [] {
  # Do this by being told the current context and the new prompt or output
  # and merging them into a single context. I wonder how other agent harnesses store the data...
  # probably a json that is suitable for the generate endpoint? or a chat endpoint...
}

def main [] {
  let model = "devstral-small-2:24b-instruct-2512-q4_K_M"
  let host = "http://workload.api.llm.skynet"

  print $"(ansi bo)Type 'exit' to quit(ansi reset)"
  print ""
  
  loop {
    let user_input = tui prompt

    if ($user_input == "exit") {
      break
    }

    let response = try {
      {
        "model": $model,
        "prompt": $user_input,
        "stream": false
      }
      | to json
      | http post $"($host)/api/generate"
      | get response
      | str join ""
    } catch { |err|
      print $err
      break
    }

    print ""
    print $"(ansi blue)*(ansi reset) ($response)"
    print ""
  }
}
