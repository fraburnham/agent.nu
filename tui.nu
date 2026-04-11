export def header []: nothing -> nothing {
  print ""
  print $"(ansi bo)Type '/exit' to quit(ansi reset)"
}

def prompt []: nothing -> string {
  mut buf = ""

  print ""
  print -n $"(ansi red)>(ansi reset) "

  loop {
    let event = input listen
    match $event.type {
      "paste" => {
        $buf += $event.content
        print -n $event.content
      }

      "key" => {
        # TODO: handle navigation keys
        let c = $event
        | get code?

        match $c {
          "enter" => {
            print ""
            break
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

  $buf
}

def response [
  context: record
]: nothing -> bool {
  let response = $context.messages
  | where role == "assistant"
  | last
  | default {}
  | get content?

  if ($response | is-empty) {
    return false
  }

  print ""
  print $"(ansi blue)*(ansi reset) ($response)"

  # TODO: this is more complex if there is a response _and_ a tool call. But since things are going async... Maybe it isn't a big deal. The tool
  # call can update the context when it is ready
  return true
}

def handle []: record -> nothing {
  let reply_to_job_id = $in.reply_to_job_id
  let context = $in.context

  if ((response $context) or (($context.messages? | length) == 1)) {
    match (prompt) {
      # TODO: /clear
      # TODO: /context-remove-latest-response
      # TODO: /context-remove-latest-prompt
      "/exit" => {
        job kill $reply_to_job_id
        
        "/exit"
        | job send 0
      }

      $user_input => {
        $user_input
        | job send $reply_to_job_id
      }
    }
  }
}

export def run []: nothing -> int {
  job spawn --tag tui { ||
    header

    loop {
      job recv
      | handle
    }
  }
}
