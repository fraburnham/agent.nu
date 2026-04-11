use api.nu
use tui.nu
use history.nu
use context/manage.nu
use tools/utils.nu

alias tools = utils

def advance [
  context: record
  user_input: oneof<string, nothing>
  history_worker_id: int
  --model: string
  --host: string
]: nothing -> record {
  $context
  | manage append prompt $user_input
  | api chat --model $model --host $host
  | tools handle agent use
  | history update $history_worker_id
}

export def run [
  manager_job_id: int
  initial_context: record
  --model: string = "qwen3.5:0.8b-bf16"
  --host: string = "http://workload.api.llm.skynet"
] {
  job spawn --tag agent { ||
    # TODO: token use tracking (iirc ollama is responding with all kinds of metrics, use them to track context fullness)
    # TODO: config file to pull model and params (temp/top_p/context length/etc) from

    let history_worker_id = history start worker # TODO: this needs to be cleaned up or it'll be a leak (so probabably have the manager start it...)
    mut context: record = $initial_context
  
    loop {
      {
        context: $context
        reply_to_job_id: (job id)
      }
      | job send $manager_job_id
      
      $context = advance $context (job recv) $history_worker_id --model $model --host $host
    }
  }
}
