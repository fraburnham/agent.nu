#!/usr/bin/env nu

use src/agent-loop.nu
use src/config.nu
use src/context
use src/tui
use src/tools.nu

def main [
  --config-file: string = "~/.agent.nu/config.json"
] {
  let config = config load $config_file

  agent-loop run $config $config.base_persona (tui run) (tools run handler $config) (context initial $config $config.base_persona)

  loop {
    match (job recv) { # Wait for an exit command from the tui
      "/exit" => {
        break
      }
    }
  }
}

