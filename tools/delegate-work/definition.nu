export const delegate_work_schema = {
  type: "function"
  function: {
    name: "delegate work"
    description: "Delegate a task to someone on your team. The response will be the result of them working on that task."
    parameters: {
      type: "object"
      properties: {
        worker: {
          description: "The role of the team member who should execute the delegated task."
          type: "string"
          enum: [
            "web-researcher"
            "local-codebase-researcher"
          ]
        }
        task: {
          description: "The task you're delegating to the team member. Be appropriately detailed."
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
