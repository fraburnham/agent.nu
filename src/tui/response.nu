def formatter [] {
  let input = $in

  if (which batcat | is-not-empty) {
    print $"($input | ^batcat -l md -n --color always --terminal-width (term size | get columns) --wrap character)"
    return
  }

  if (which bat | is-not-empty) {
    print $"($input | ^bat -l md -n --color always --terminal-width (term size | get columns) --wrap character)"
    return
  }

  print -n $"(ansi blue)*(ansi reset) ($input)"
}

export def main [
  context: record
] {
  let response = $context.messages
  | where role == "assistant"
  | last
  | default {}

  if ($response.content? | is-not-empty) {
    print $"(ansi erase_entire_line)(ansi --escape "1G")"
    print -n $"(char backspace)(char backspace)(char backspace)" # Matches prompt length (TODO do gooder)

    $response.content
    | formatter
  }

  if ($response.tool_calls? | is-not-empty) {
    print $"(ansi erase_entire_line)(ansi --escape "1G")"

    $response.tool_calls
    | each { |tool_call|
      print $"(ansi yellow)- ($tool_call.function.name)(ansi reset)"
    }
  }
}
