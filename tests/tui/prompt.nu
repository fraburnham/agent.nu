use std/assert
use ../runner

export def --wrapped print [...args] {
  runner stub STUB_PRINT ...$args

  # Print returns null
  null
}

use ../../src/tui

# ignore
def "test that the prompt is shown once the ready-for-input message is received" [] { # This test does not work.
  with-env {
    STUB_PRINT: { |...args|
      # TODO: these have the weakness of not failing if not called, but solving that means state management...
      match ($args | length)  {
        1 => {
          assert equal "" $args.0
        }
        $len => {
          assert equal 2 $len
          assert equal "-n" $args.0
          assert equal $"(ansi red)>(ansi reset) " $args.1
        }
      }
    }
  } {
    let prompt_job_id = tui prompt

    {
      type: ready-for-input
      reply_to_job_id: (job id)
    }
    | job send $prompt_job_id

    sleep 1sec
  }
}

# def "test that key events are added to the buffer" [] {
#   assert false
# }

# def "test that backspace updates the view and buffer" [] {
#   assert false
# }

# def "test that paste events are added to the buffer" [] {
#   assert false
# }

export def main [] {
  runner run
}
