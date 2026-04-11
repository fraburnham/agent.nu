use api.nu
use tui.nu
use history.nu
use context.nu

def advance [
  context: record
  user_input: oneof<string, nothing>
  history_worker_id: int
  tool_handler: closure # This is a hack to avoid an import loop. There's probably a better way, though.
  --model: string
  --host: string
]: nothing -> record {
  $context
  | context append prompt $user_input
  | api chat --model $model --host $host
  | do $tool_handler # This is a hack to avoid an import loop. There's probably a better way, though. Message passing?
  | history update $history_worker_id
}

export def run [
  context: record
  tool_handler: closure # This is a hack to avoid an import loop. There's probably a better way, though.
  manager_job_id: int
  persona: string
  --model: string = "qwen3.5:0.8b-bf16"
  --host: string = "http://workload.api.llm.skynet"
] {
  job spawn --tag agent { ||
    # TODO: token use tracking (iirc ollama is responding with all kinds of metrics, use them to track context fullness)
    # TODO: config file to pull model and params (temp/top_p/context length/etc) from

    let history_worker_id = history start worker # TODO: this needs to be cleaned up or it'll be a leak
    mut context: record = initial $persona
  
    loop {
      {
        context: $context
        reply_to_job_id: (job id)
      }
      | job send $manager_job_id
      
      $context = advance $context (job recv) $history_worker_id $tool_handler --model $model --host $host
    }
  }
}
