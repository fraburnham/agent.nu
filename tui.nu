export def prompt []: nothing -> string {
  mut buf = ""

  print -n $"(ansi red)>(ansi reset) "

  loop {
    let c = input listen
    | get code?

    match $c {
      # TODO: handle navigation keys!
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

  $buf
}

# def working-indicator [] {
#   # It'd be nice to have... Probably a matter of render a char
#   # then backspace and render a diff one
#   # but idk how this loop would hear back from the api call
#   # probably a job and such
# }

# TODO: post-process the markdown output with ansi chars? Like leave it markdown syntax but also enrich stuff like headers, bold, italic, code (way bonus points for syntax highlighting)

# also is this failing open and just hanging or was that old shells that didn't cleanup?
