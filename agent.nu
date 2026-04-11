#!/usr/bin/env nu

use agent-loop.nu
use context.nu
use tui.nu
use tools.nu

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
