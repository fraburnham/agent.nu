use tools/delegate-work.nu
use tools/utils.nu
use context/manage.nu

export def "run handler" [
  config: record
] {
  job spawn --description tool-use-handler { ||
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

      let context = $tool_calls
      | reduce --fold $context { |tool_call, context|
        let function = $tool_call.function

        {
          id: $tool_call.id?
          role: "tool"
          content: (
            match $function.name {
              "delegate-work" => {
                let tool_handler_job_id = run handler $config
                let response = delegate-work $config $tool_handler_job_id $function.arguments

                job kill $tool_handler_job_id
                $response
              }

              _ => {
                "No matching tool found."
              }
            }
          )
        }
        | manage append response $context
      }

      {
        context: $context
        type: context
      }
      | job send $message.reply_to_job_id
    }
  }
}
