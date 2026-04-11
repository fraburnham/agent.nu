export def "handle agent use" []: record -> record {
  let context = $in
  let tool_calls = $context.messages
  | last
  | get tool_calls?
  | default []

  $tool_calls
  | reduce --fold $context { |tool_call, context|
    let function = $tool_call.function

    {
      id: $tool_call.id?
      role: "tool"
      content: (
        match $function.name {
          $delegate_work_name => {
            delegate work $function.arguments
          }
        }
      )
    }
    | context append response $context
  }
}

export def "available to agent" [
  tool_schemas: record
  agent: string
] {
  $tool_schemas
  | get $agent
}
