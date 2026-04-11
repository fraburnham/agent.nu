use tools/definitions.nu [tool_schemas]
use tools/delegate-work.nu
use tools/utils.nu
use context/manage.nu

export def "available to agent" [
  agent: string
] {
  utils available to agent $tool_schemas $agent
}

export def "run handler" [] {
  job spawn --tag tool-use-handler { ||
    loop {
      let message: record<context: record, reply_to_job_id: int> = job recv
      let context: record = $message.context
      let tool_calls = $context.messages
      | last
      | get tool_calls?
      | default []

      if ($tool_calls | is-empty) {
        continue
      }

      $tool_calls
      | reduce --fold $context { |tool_call, context|
        let function = $tool_call.function

        {
          id: $tool_call.id?
          role: "tool"
          content: (
            match $function.name {
              "delegate-work" => {
                delegate-work $function.arguments
              }

              _ => {
                "No matching tool found."
              }
            }
          )
        }
        | manage append response $context
      }
      | job send $message.reply_to_job_id
    }
  }
}
