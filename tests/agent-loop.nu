use std/assert
use runner

use ../src/agent-loop.nu

def "test it out" [] {
  assert equal 1 2
}

export def main [] {
  runner run
}
