use ../agent-loop.nu
use utils.nu

export const delegate_work_name = "delegate work"

export const delegate_work_schema = {
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

export def "delegate work" [
  params: record<worker: string, task: string>
]: nothing -> string {
  let agent_job_id = agent-loop run (initial high-level-leader) { tools handle agent use } (tui run) $params.worker
  mut response = ""

  $params.task
  | job send $agent_job_id
  
  loop {
    match (job recv) {
      $context => {
        print ($context)
        # ^^ use that to get the current final response
        # Once I have an assistant repsponse w/o tool use the delegation is done
      }
    }
  }

  if ($response | is-empty) {
    "Delegation failed"
  } else {
    $response
  }
}
