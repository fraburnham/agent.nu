export def main []: nothing -> int {
  job spawn --description prompt { ||
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

      match $event {
        {type: "ready-for-input", reply_to_job_id: $r} => {
          $ready_for_input = true
          $reply_to_job_id = $r

          print $"(ansi erase_entire_line)(ansi --escape "1G")"
          print -n $"(ansi red)>(ansi reset) ($buf)"
        }

        {type: "paste", content: $content} => {
          $buf += $content
          print -n $content
        }

        {type: "key", code: $c, modifiers: $m} => {
          # TODO: handle navigation keys (up for recall, left to go back in the buf (this makes updating fun!) etc)
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
              # TODO: don't backspace if the buffer is empty
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
