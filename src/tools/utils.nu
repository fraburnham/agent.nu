export def use [
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

export def "available to agent" [
  tool_schemas: record
  agent: string
] {
  $tool_schemas
  | get $agent
}

