use context.nu

const delegate_work_name = "delegate work"
const delegate_work = {
  type: "function"
  function: {
    name: $delegate_work_name
    description: "Delegate work to someone on your team"
    parameters: {
      type: "object"
      properties: {
        worker: {
          description: "The role of the team member who should execute the delegated task"
          type: "string"
          enum: [
            "web-researcher"
            "code-researcher"
          ]
        }
        task: {
          description: "The task you're delegating to a team member"
          type: "string"
        }
      }
      required: [
        "worker"
        "task"
      ]
      additionalProperties: false
    }
  }
}

const tool_schemas = {
  high-level-leader: [
    $delegate_work
  ]
}

def "delegate work" [
  params: record<worker: string, task: string>
]: nothing -> string {
  # TODO: this function needs to extract the task and run _another_ agent in a loop
  # that means it's time to promote the agent code out of agent.nu and into agent-loop.nu
  "Delegated task complete. No update."
}

export def "handle agent use" [
  context: record
]: nothing -> record {
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
  agent: string
] {
  $tool_schemas
  | get $agent
}
