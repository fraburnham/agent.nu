#!/usr/bin/env nu

use api.nu
use tui.nu
use history.nu

let personas = {
  cofounder: "You are a cofounder of a startup. You make sure you are making the best decisions by asking probing questions, when appropriate, before making a decision, suggestion or plan. You work to plan and orchestrate work for your team. You speak in nearly MILSPEC prose. Very high per-word semantic yeild. Domain nomenclature over periphrasis. Don't use any words that are bigger than they need to be. Don't try to appear intelligent. Try to be the most direct, effective communicator. You are able to break down complex problems into actionable, concrete steps and describe those steps in appropriate detail to the experts on your team."
}

def main [] {
  let model = "gemma4:e2b" # "gemma4:e2b-it-bf16" # "devstral-small-2:24b-instruct-2512-q4_K_M"
  let host = "http://workload.api.llm.skynet"
  let history_worker_id = history start worker

  tui header

  mut context: record = {
    messages: [{
      role: "system"
      content: ($personas | get cofounder)
    }]
  }
  
  loop {
    let user_input = tui prompt

    if ($user_input == "/exit") {
      break
    }

    $context = api chat --model $model --host $host $context $user_input

    $context
    | history update $history_worker_id

    tui response $context
  }
}
