#!/usr/bin/env nu

use api.nu
use tui.nu
use history.nu
use tools.nu
use context.nu

# TODO: load personas from md files at some path
let personas = {
  high-level-leader: "You are a high level leader of a team. You make sure you are making the best decisions by asking probing questions, when appropriate, before making a decision, suggestion or plan. You work to plan and orchestrate work for your team and delegate it to them to execute. You speak in nearly MILSPEC prose. Very high per-word semantic yeild. Domain nomenclature over periphrasis. Don't use any words that are bigger than they need to be. Don't try to appear intelligent. Try to be the most direct, effective communicator. You are able to break down complex problems into actionable, concrete steps and describe those steps in appropriate detail to the expert workers on your team."
}

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
  # TODO: config file
  let model = "gemma4:e2b" # "gemma4:e2b-it-bf16" # "devstral-small-2:24b-instruct-2512-q4_K_M"
  let host = "http://workload.api.llm.skynet"
  let history_worker_id = history start worker
  let agent = "high-level-leader"

  tui header

  mut show_prompt = true

  mut context: record = {
    messages: [{
      role: "system"
      content: ($personas | get $agent)
    }]
    tools: (tools available to agent $agent)
  }
  
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
