export def "get state" []: record -> string {
  let context = $in

  let last_message = ($context.messages? | default [])
  | last

  match [
    $last_message.role?
    ($last_message.content? | is-not-empty)
    ($last_message.thinking? | is-not-empty)
    ($last_message.tool_calls? | is-not-empty)
  ] {
    ["assistant", _, _, true] => {
      "awaiting-tool-calls"
    }

    ["system", _, _, _] | ["assistant", true, _, false] => {
      "awaiting-controller-input"      
    }

    ["user", _, _, _] | _ => {
      "awaiting-model"
    }
  }
}
