export def header []: nothing -> nothing {
  print ""
  print $"(ansi bo)Type '/exit' to quit(ansi reset)"
}

def prompt []: nothing -> int {
  job spawn --tag prompt { ||
    mut buf = ""
    mut reply_to_job_id = 0
    mut ready_for_input = false

    loop {
      let event = try {
        if $ready_for_input {
          try {
            # Wait for input
            input listen --timeout 1sec
          } catch {
            try {
              # Try to get a message but don't wait, input is the priority
              job recv --timeout 0sec
            }
          }
        } else {
          # Not ready for input. Wait until we get a message that could be the ready message
          job recv
        }
      }

      if ($event | is-empty) {
        continue
      }

      match $event.type {
        "ready-for-input" => {
          $ready_for_input = true
          $reply_to_job_id = $event.reply_to_job_id

          print ""
          print -n $"(ansi red)>(ansi reset) ($buf)"
        }

        "paste" => {
          $buf += $event.content
          print -n $event.content
        }

        "key" => {
          # TODO: handle navigation keys (up for recall, left to go back in the buf (this makes updating fun!) etc)
          let c = $event
          | get code?

          match $c {
            "enter" => {
              print ""

              {
                type: "user-input"
                user_input: $buf
              }
              | job send $reply_to_job_id

              $buf = ""
              $ready_for_input = false
            }
      
            "backspace" => {
              $buf = $buf
              | str substring ..-2

              print -n $"(char backspace) (char backspace)"
            }

            _ => {
              if ($c | is-not-empty) {
                $buf += $c
                print -n $c
              }
            }
          }

        }
      }
    }
  }
}

def response [
  context: record
]: nothing -> bool {
  let response = $context.messages
  | where role == "assistant"
  | last
  | default {}

  mut ready_for_user_input = false

  if ($response.content? | is-not-empty) {
    $ready_for_user_input = true

    print (ansi erase_entire_line)
    print -n $"(char backspace)(char backspace)(char backspace)" # Matches prompt length (TODO do gooder)
    print $"(ansi blue)*(ansi reset) ($response.content)"
  }

  if ($response.tool_calls? | is-not-empty) {
    print (ansi erase_entire_line)

    $response.tool_calls
    | each { |tool_call|
      print $"(ansi yellow)- ($tool_call.function.name)(ansi reset)"
    }
  }

  return $ready_for_user_input
}

def handle [
  prompt_job_id: int
]: record -> nothing {
  let message = $in
  let context = $in.context

  if (response $context) or (($context.messages? | length) == 1) {
    {
      type: "ready-for-input"
      reply_to_job_id: $message.reply_to_job_id
    }
    | job send $prompt_job_id
  }
}

export def run []: nothing -> int {
  job spawn --tag tui { ||
    let prompt_job_id = prompt

    header

    loop {
      job recv
      | handle $prompt_job_id
    }
  }
}
