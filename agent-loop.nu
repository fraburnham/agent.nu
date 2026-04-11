use api.nu
use tui.nu
use history.nu
use context/manage.nu
use tools/utils.nu

def advance [
  history_worker_id: int
  tool_handler_job_id: int
  --model: string
  --host: string
]: record -> record {
  api chat --model $model --host $host
  | utils use $tool_handler_job_id
  | history update $history_worker_id
}

export def run [
  manager_job_id: int
  tool_handler_job_id: int
  initial_context: record
  --model: string = "qwen3.5:0.8b-bf16"
  --host: string = "http://workload.api.llm.skynet"
] {
  job spawn --tag agent-loop { ||
    # TODO: token use tracking (iirc ollama is responding with all kinds of metrics, use them to track context fullness)
    # TODO: config file to pull model and params (temp/top_p/context length/etc) from

    let history_worker_id = history start worker # TODO: this needs to be cleaned up or it'll be a leak (so probabably have the manager start it...)
    mut context: record = $initial_context
  
    loop {
      # Send the manager the current/advanced context
      {
        context: $context
        reply_to_job_id: (job id)
      }
      | job send $manager_job_id

      # AHH! We're back to needing to skip the wait if there is a tool response...
      # So instead of being _sync_ the tool can _start_ the 

      # Wait for the manager to respond with a context, then advance it
      $context = job recv
      | advance $history_worker_id $tool_handler_job_id --model $model --host $host
    }
  }
}
