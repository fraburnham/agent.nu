#!/usr/bin/env nu

use agent-loop.nu
use personas.nu [personas]
use tools.nu
use tui.nu

def initial [
  agent: string
] {
  {
    messages: [{
      role: "system"
      content: ($personas | get $agent)
    }]
    tools: (tools available to agent $agent)
  }
}

def main [] {
  agent-loop run (initial high-level-leader) { tools handle agent use } (tui run) high-level-leader

  loop {
    match (job recv) {
      "/exit" => {
        break
      }
    }
  }
}
