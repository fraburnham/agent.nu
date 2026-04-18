use std/assert
use ../runner
use ../runner [mock_table]

export def main [] {
  runner run
}

alias real_print = print

export def --wrapped "input listen" [...args] {
  error make { msg: "Mock no input message" }
}

export def print [
  --no-newline (-n)
  --stderr (-e)
  ...args
] {
  let pipe_data = $in

  $pipe_data
  | runner mock print ...$args

  $pipe_data
  | match [$no_newline $stderr] {
    [true false] => {
      real_print -n ...$args
    }

    [false true] => {
      real_print -e ...$args
    }

    _ => {
      real_print ...$args
    }
  }
}

use ../../src/tui

hide print # So the runner's calls aren't mocked

def "test that the prompt is shown once the ready-for-input message is received" [] {
  let prompt_job_id = tui prompt

  {
    type: ready-for-input
    reply_to_job_id: (job id)
  }
  | job send $prompt_job_id

  sleep 0.2sec

  runner mock assert called times print 2
  runner mock assert called times with args print [$"(ansi red)>(ansi reset) "] 1
}

def "test that key events are added to the buffer" [] {
  let prompt_job_id = tui prompt

  # Give the worker a job to reply to
  {
    type: ready-for-input
    reply_to_job_id: (job id)
  }
  | job send $prompt_job_id

  # Send a key
  {
    type: key
    code: "k"
    modifiers: null
  }
  | job send $prompt_job_id

  # Send enter
  {
    type: key
    code: "enter"
    modifiers: null
  }
  | job send $prompt_job_id

  # Await a message
  let message = job recv --timeout 0.1sec

  assert equal "k" $message.user_input
}

def "test that backspace updates the view and buffer" [] {
  let prompt_job_id = tui prompt

  # Give the worker a job to reply to
  {
    type: ready-for-input
    reply_to_job_id: (job id)
  }
  | job send $prompt_job_id

  # Send a key
  {
    type: key
    code: "k"
    modifiers: null
  }
  | job send $prompt_job_id

  # Send backspace
  {
    type: key
    code: "backspace"
    modifiers: null
  }
  | job send $prompt_job_id

  # Send a new key
  {
    type: key
    code: "n"
    modifiers: null
  }
  | job send $prompt_job_id
  
  # Send enter
  {
    type: key
    code: "enter"
    modifiers: null
  }
  | job send $prompt_job_id

  # Await a message
  let message = job recv --timeout 0.1sec

  assert equal "n" $message.user_input
}

def "test that paste events are added to the buffer" [] {
  let prompt_job_id = tui prompt
  let expected = "This is only a test"

  # Give the worker a job to reply to
  {
    type: ready-for-input
    reply_to_job_id: (job id)
  }
  | job send $prompt_job_id

  # Send paste
  {
    type: paste
    content: $expected
  }
  | job send $prompt_job_id

  # Send enter
  {
    type: key
    code: "enter"
    modifiers: null
  }
  | job send $prompt_job_id

  # Await a message
  let message = job recv --timeout 0.1sec

  assert equal $expected $message.user_input
}
