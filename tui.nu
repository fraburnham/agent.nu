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

  return true
}

export def handle [
  $context
]: nothing -> string {
  print "debug"
  print ($context.messages | get role)

  if ((response $context) or (($context.messages? | length) == 1)) {
    prompt
  }
}
