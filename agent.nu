#!/usr/bin/env nu

use agent-loop.nu
use context.nu
use tui.nu

def main [] {
  agent-loop run (tui run) (context initial high-level-leader)

  loop {
    match (job recv) {
      "/exit" => {
        break
      }
    }
  }
}
