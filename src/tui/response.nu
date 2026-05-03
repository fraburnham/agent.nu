export def main [
  context: record
]: nothing -> bool {
  let response = $context.messages
  | where role == "assistant"
  | last
  | default {}

  mut ready_for_user_input = false

  if ($response.content? | is-not-empty) {
    $ready_for_user_input = true

    print $"(ansi erase_entire_line)(ansi --escape "1G")"
    print -n $"(char backspace)(char backspace)(char backspace)" # Matches prompt length (TODO do gooder)
    if (which batcat | is-not-empty) {
      print $"($response.content | ^batcat -l md -n --color always --terminal-width (term size | get columns) --wrap character)"
    } else {
      print -n $"(ansi blue)*(ansi reset) ($response.content)"
    }
  }

  if ($response.tool_calls? | is-not-empty) {
    print $"(ansi erase_entire_line)(ansi --escape "1G")"

    $response.tool_calls
    | each { |tool_call|
      print $"(ansi yellow)- ($tool_call.function.name)(ansi reset)"
    }
  }

  return $ready_for_user_input
}
