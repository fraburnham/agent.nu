#!/usr/bin/env nu

use api.nu
use tui.nu
use history.nu
use tools.nu
use context.nu

def advance_context [
  context: record
  user_input: oneof<string, nothing>
  --model: string
  --host: string
]: nothing -> record {
  if ($user_input | is-not-empty) {
    $context
    | context append prompt $user_input
    | api chat --model $model --host $host
  } else {
    tools handle agent use $context
    | api chat --model $model --host $host
  }
}

def main [] {
  # TODO: token use tracking (iirc ollama is responding with all kinds of metrics, use them to track context fullness)
  # TODO: config file
  let model = "gemma4:e2b" # "gemma4:e2b-it-bf16" # "devstral-small-2:24b-instruct-2512-q4_K_M"
  let host = "http://workload.api.llm.skynet"
  let history_worker_id = history start worker
  let agent = "high-level-leader"

  tui header

  mut context: record = context initial $agent
  
  loop {
    history update $history_worker_id $context

    let user_input = tui handle $context

    match $user_input {
      "/exit" => {
        break
      }
    }

    $context = advance_context $context $user_input --model $model --host $host
  }
}
