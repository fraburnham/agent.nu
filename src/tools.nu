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
        let tool_path = $"($config.tools_path)/($function.name)/run"

        {
          id: $tool_call.id?
          role: "tool"
          content: (
            if not ($tool_path | path exists) {
              "No matching tool found. Retrying the call will not help."
            } else {
              {
                config: $config
                tool_call: $tool_call
              }
              | to json
              | run-external ($"($config.tools_path)/($function.name)/run" | path expand)
              | complete
              | do {
                let result = $in

                if $result.exit_code == 0 {
                  $result.stdout
                } else {
                  [$result.stdout, $result.stderr]
                  | str join "\n"
                }
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

export def run [
  tool_handler_job_id: int
]: record -> record {
  let context = $in

  {
    context: $context
    reply_to_job_id: (job id)
  }
  | job send $tool_handler_job_id

  # This doesn't await the response because the agent-loop is awaiting the response.

  $context
}

export def "available to persona" [
  config: record
  persona: string
] {
  personas config $config $persona
  | get tools
  | each { |tool_name|
    open ($"($config.tools_path)/($tool_name)/definition.json" | path expand)
  }
}
