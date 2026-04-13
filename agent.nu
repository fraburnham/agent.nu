#!/usr/bin/env nu

use src/agent-loop.nu
use src/context
use src/tui
use src/tools.nu

def main [] {
  agent-loop run (tui run) (tools run handler) (context initial high-level-leader)

  loop {
    match (job recv) { # Wait for an exit command from the tui
      "/exit" => {
        break
      }
    }
  }
}
