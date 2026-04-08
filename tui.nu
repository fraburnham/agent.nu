export def header []: nothing -> nothing {
  print ""
  print $"(ansi bo)Type '/exit' to quit(ansi reset)"
}

export def prompt []: nothing -> string {
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

export def response [
  context: record
]: nothing -> nothing {
  let response = $context.messages
  | last
  | get content

  print ""
  print $"(ansi blue)*(ansi reset) ($response)"
}

